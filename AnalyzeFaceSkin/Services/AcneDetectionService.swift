//
//  AcneDetectionService.swift
//  AnalyzeFaceSkin
//
//  ⚠️  YOLO MODEL REQUIRED ⚠️
//  Export your YOLO11-seg / YOLOv8-seg acne model to CoreML:
//    Python: model.export(format='coreml', nms=False)
//  Then drag 'AcneDetector.mlpackage' into the Xcode project and
//  make sure it is added to the AnalyzeFaceSkin target.
//
//  Expected model I/O:
//    Input  : 640 × 640 RGB image (Vision resizes automatically)
//    Output0: MLMultiArray [1, 4+nc+32, 8400] — raw predictions
//    Output1: MLMultiArray [1, 32, 160, 160]  — prototype masks (optional)
//

import UIKit
import CoreML
import Vision

class AcneDetectionService {

    // MARK: - YOLO Configuration

    private enum YOLO {
        /// Name of the CoreML model file (without extension).
        /// Add yolo11AcneClahe.mlpackage to your Xcode target.
        static let modelName       = "yolo11AcneClahe"

        static let inputW          = 640
        static let inputH          = 640
        static let numClasses      = 1      // single class: acne
        static let numProtos       = 32     // mask-prototype coefficients
        static let confThresh: Float = 0.25
        static let iouThresh:  Float = 0.45

        /// 4 box coords + numClasses + numProtos
        static var featureDim: Int { 4 + numClasses + numProtos }  // = 37
    }

    // MARK: - Model Loading

    /// Which model is currently loaded
    private enum LoadedModel {
        case yolo(VNCoreMLModel)              // yolo11AcneClahe.mlpackage (YOLO11)
        case segmenter(VNCoreMLModel)         // SkinConditionSegmenter.mlpackage (fallback)
    }

    private let loadedModel: LoadedModel? = {
        let cfg = MLModelConfiguration()
        cfg.computeUnits = .cpuOnly

        // ── 1. Try yolo11AcneClahe generated model class (Xcode auto-gen) ────
        if let modelObj = try? yolo11AcneClahe(configuration: cfg) {
            do {
                let vm = try VNCoreMLModel(for: modelObj.model)
                print("[AcneDetector] ✅ Loaded yolo11AcneClahe model class")
                return .yolo(vm)
            } catch {
                print("[AcneDetector] VNCoreMLModel creation failed: \(error)")
            }
        }

        // ── 2. Try loading yolo11AcneClahe from main bundle ──────────────────
        if let url = Bundle.main.url(forResource: YOLO.modelName, withExtension: "mlpackage")
                  ?? Bundle.main.url(forResource: YOLO.modelName, withExtension: "mlmodel") {
            do {
                let model = try MLModel(contentsOf: url, configuration: cfg)
                let vm    = try VNCoreMLModel(for: model)
                print("[AcneDetector] ✅ Loaded YOLO model from bundle: \(YOLO.modelName)")
                return .yolo(vm)
            } catch {
                print("[AcneDetector] YOLO load failed: \(error)")
            }
        } else {
            print("[AcneDetector] ℹ️  \(YOLO.modelName).mlpackage not found — using SkinConditionSegmenter fallback")
        }

        // ── 3. Fallback: SkinConditionSegmenter ─────────────────────────────
        do {
            let seg = try SkinConditionSegmenter(configuration: cfg)
            let vm  = try VNCoreMLModel(for: seg.model)
            print("[AcneDetector] ✅ Fallback: SkinConditionSegmenter loaded")
            return .segmenter(vm)
        } catch {
            print("[AcneDetector] ❌ SkinConditionSegmenter load also failed: \(error)")
            return nil
        }
    }()

    // MARK: - Public Types

    struct ConditionScore {
        let level:         String   // "low" | "moderate" | "high"
        let confidence:    Double   // mean detection confidence
        let density:       Double   // total acne area (scaled 0-255 for legacy compat)
        let boundingBoxes: [SkinBoundingBox]
    }

    struct DetectionResult {
        let acne:         ConditionScore
        let clahePreview: UIImage?
    }

    // MARK: - Internal Types

    private struct YOLODetection {
        let x1, y1, x2, y2: Float  // normalized [0-1] in the 640-px letterboxed space
        let confidence: Float
        let maskCoeffs: [Float]     // 32 prototype-mask coefficients
    }

    /// Stores the letterboxing geometry so we can map model coords → original image coords.
    private struct LetterboxInfo {
        let scale: Float   // uniform scale (= min(640/srcW, 640/srcH))
        let padX:  Float   // left-pad pixels in 640-space
        let padY:  Float   // top-pad pixels in 640-space
        let srcW:  Float   // original image width
        let srcH:  Float   // original image height
    }

    private struct PreprocessedImages {
        let modelInput:  CGImage        // 640×640 BGRA (L-channel CLAHE-enhanced) — fed to Vision
        let clahe:       UIImage        // debug: L-channel CLAHE preview image
        let letterbox:   LetterboxInfo
    }

    // MARK: - Public API

    func detect(image: UIImage,
                completion: @escaping (Result<DetectionResult, Error>) -> Void) {

        guard let loaded = loadedModel else {
            completion(.failure(makeError(
                "No model available. Add yolo11AcneClahe.mlpackage or ensure SkinConditionSegmenter is in the project.",
                code: 404)))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let prep = self.buildPreprocessedImages(from: image) else {
                completion(.failure(self.makeError("Preprocessing failed", code: 400)))
                return
            }

            switch loaded {
            case .yolo(let model):
                self.runYOLO(model: model, prep: prep, completion: completion)
            case .segmenter(let model):
                self.runSegmenter(model: model, prep: prep, completion: completion)
            }
        }
    }

    // MARK: - YOLO Inference Path

    private func runYOLO(model: VNCoreMLModel,
                         prep: PreprocessedImages,
                         completion: @escaping (Result<DetectionResult, Error>) -> Void) {
        let request = VNCoreMLRequest(model: model) { [weak self] req, err in
            guard let self = self else { return }
            if let err = err { completion(.failure(err)); return }
            let result = self.parseYOLOOutput(
                observations: req.results ?? [],
                lb:           prep.letterbox,
                clahe:        prep.clahe
            )
            completion(.success(result))
        }
        request.imageCropAndScaleOption = .scaleFill  // image already 640×640
        do {
            try VNImageRequestHandler(cgImage: prep.modelInput, options: [:]).perform([request])
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - SkinConditionSegmenter Fallback Path

    private func runSegmenter(model: VNCoreMLModel,
                              prep: PreprocessedImages,
                              completion: @escaping (Result<DetectionResult, Error>) -> Void) {
        let request = VNCoreMLRequest(model: model) { [weak self] req, err in
            guard let self = self else { return }
            if let err = err { completion(.failure(err)); return }

            let results = req.results ?? []

            // Auto-detect output format:
            // • VNCoreMLFeatureValueObservation + MLMultiArray → YOLO format
            // • VNPixelBufferObservation                       → classic pixel mask
            if results.first is VNCoreMLFeatureValueObservation {
                print("[AcneDetector] SkinConditionSegmenter outputs MLMultiArray → using YOLO parser")
                let result = self.parseYOLOOutput(
                    observations: results,
                    lb:           prep.letterbox,
                    clahe:        prep.clahe
                )
                completion(.success(result))
            } else {
                let result = self.parseSegmenterMask(
                    results:   results,
                    clahe:     prep.clahe
                )
                completion(.success(result))
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        do {
            try VNImageRequestHandler(cgImage: prep.modelInput, options: [:]).perform([request])
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - YOLO Output Parsing

    private func parseYOLOOutput(observations: [VNObservation],
                                  lb: LetterboxInfo,
                                  clahe: UIImage) -> DetectionResult {

        // Collect MLMultiArray outputs; identify by shape
        var predArray: MLMultiArray? = nil
        var protoArray: MLMultiArray? = nil

        for obs in observations {
            guard let feat = obs as? VNCoreMLFeatureValueObservation,
                  let arr  = feat.featureValue.multiArrayValue else { continue }

            let shape = arr.shape.map { $0.intValue }
            print("[AcneDetector] output '\(feat.featureName)' shape=\(shape) dtype=\(arr.dataType.rawValue)")

            guard arr.dataType == .float32, shape.count >= 2 else { continue }

            let dimSet = Set(shape)
            let fd     = YOLO.featureDim
            if (dimSet.contains(fd) || dimSet.contains(fd + 1)) && predArray == nil {
                predArray = arr
            } else if shape.contains(32) && (shape.contains(160) || shape.contains(80)) {
                protoArray = arr
            }
        }

        guard let pred = predArray else {
            print("[AcneDetector] ⚠️  No prediction tensor found in model output")
            return defaultResult(clahe: clahe)
        }

        // ── Decode → filter by confidence → NMS ────────────────────────────
        let candidates = decodePredictions(pred)
        print("[AcneDetector] raw candidates: \(candidates.count)")
        guard !candidates.isEmpty else {
            return defaultResult(clahe: clahe)
        }

        let detections = applyNMS(candidates)
        print("[AcneDetector] after NMS: \(detections.count) detections")

        // ── Convert letterboxed coords → original-image-normalized coords ──
        let scaledW = lb.scale * lb.srcW   // width of the scaled image within 640-canvas
        let scaledH = lb.scale * lb.srcH
        let W = Float(YOLO.inputW), H = Float(YOLO.inputH)

        let boxes: [SkinBoundingBox] = detections.compactMap { d in
            // x1 is in [0,1] relative to 640px canvas
            let x1 = max(0.0, min(1.0, Double((d.x1 * W - lb.padX) / scaledW)))
            let y1 = max(0.0, min(1.0, Double((d.y1 * H - lb.padY) / scaledH)))
            let x2 = max(0.0, min(1.0, Double((d.x2 * W - lb.padX) / scaledW)))
            let y2 = max(0.0, min(1.0, Double((d.y2 * H - lb.padY) / scaledH)))
            let w  = x2 - x1
            let h  = y2 - y1
            guard w > 0.005, h > 0.005 else { return nil }

            let polyPoints: [CGPoint]?
            if let proto = protoArray {
                polyPoints = self.extractYOLOPolygon(det: d, proto: proto, lb: lb)
            } else {
                polyPoints = self.generateEllipsePolygon(det: d, lb: lb)
            }

            return SkinBoundingBox(x: x1, y: y1, width: w, height: h, polygonPoints: polyPoints)
        }

        return DetectionResult(
            acne:         makeScore(detections: detections, boxes: boxes),
            clahePreview: clahe
        )
    }

    // MARK: - Prediction Decoding

    private func decodePredictions(_ arr: MLMultiArray) -> [YOLODetection] {
        guard arr.dataType == .float32 else {
            print("[AcneDetector] Unexpected dtype \(arr.dataType.rawValue)"); return []
        }

        let shape   = arr.shape.map   { $0.intValue }
        let strides = arr.strides.map { $0.intValue }
        let ptr     = arr.dataPointer.assumingMemoryBound(to: Float32.self)

        // Determine layout (channel-first or channel-last) by comparing axis sizes.
        // YOLO exports: [1, featureDim, numAnchors] → channel-first (CHW)
        //               [1, numAnchors, featureDim] → channel-last  (HWC)
        let numFeats:    Int
        let numAnchors:  Int
        let featStride:  Int    // pointer stride to move one feature forward
        let anchorStride: Int   // pointer stride to move one anchor forward

        let flat = shape.filter { $0 > 1 }   // strip batch dimension of 1
        guard flat.count >= 2 else { return [] }

        let dim0 = flat[flat.count - 2]
        let dim1 = flat[flat.count - 1]

        // The smaller dimension is typically featureDim (37),
        // the larger is numAnchors (8400).
        if dim0 <= dim1 {
            // CHW: [..., featureDim, numAnchors]
            numFeats     = dim0;   numAnchors  = dim1
            featStride   = strides[strides.count - 2]
            anchorStride = strides[strides.count - 1]
        } else {
            // HWC: [..., numAnchors, featureDim]
            numAnchors   = dim0;   numFeats    = dim1
            anchorStride = strides[strides.count - 2]
            featStride   = strides[strides.count - 1]
        }

        guard numFeats >= 4 + YOLO.numClasses else {
            print("[AcneDetector] featureDim \(numFeats) too small (need ≥ \(4+YOLO.numClasses))")
            return []
        }

        let W   = Float(YOLO.inputW)
        let H   = Float(YOLO.inputH)
        let nc  = YOLO.numClasses

        var results = [YOLODetection]()
        results.reserveCapacity(512)

        for i in 0..<numAnchors {
            let base = i * anchorStride

            let cx = ptr[base + 0 * featStride]
            let cy = ptr[base + 1 * featStride]
            let bw = ptr[base + 2 * featStride]
            let bh = ptr[base + 3 * featStride]

            // Class score — apply sigmoid only when raw value looks like logits (< 0 or > 1)
            var conf = ptr[base + 4 * featStride]
            if conf < 0.0 || conf > 1.0 { conf = sigmoid(conf) }

            guard conf >= YOLO.confThresh else { continue }

            // Convert (cx, cy, w, h) → (x1, y1, x2, y2), normalizing to [0,1]
            let x1n: Float
            let y1n: Float
            let x2n: Float
            let y2n: Float

            if cx > 1.0 || cy > 1.0 || bw > 1.0 || bh > 1.0 {
                // Pixel-space output
                x1n = (cx - bw * 0.5) / W
                y1n = (cy - bh * 0.5) / H
                x2n = (cx + bw * 0.5) / W
                y2n = (cy + bh * 0.5) / H
            } else {
                // Already normalized to [0,1]
                x1n = cx - bw * 0.5
                y1n = cy - bh * 0.5
                x2n = cx + bw * 0.5
                y2n = cy + bh * 0.5
            }

            guard x2n > x1n, y2n > y1n,
                  x2n > 0, x1n < 1,
                  y2n > 0, y1n < 1 else { continue }

            // Mask coefficients (32 values after 4+nc)
            let coeffStart       = 4 + nc
            let nCoeffs          = min(YOLO.numProtos, numFeats - coeffStart)
            var coeffs           = [Float](repeating: 0, count: YOLO.numProtos)
            for k in 0..<nCoeffs {
                coeffs[k] = ptr[base + (coeffStart + k) * featStride]
            }

            results.append(YOLODetection(
                x1: max(0, x1n), y1: max(0, y1n),
                x2: min(1, x2n), y2: min(1, y2n),
                confidence: conf,
                maskCoeffs: coeffs
            ))
        }
        return results
    }

    // MARK: - Non-Maximum Suppression (greedy)

    private func applyNMS(_ dets: [YOLODetection]) -> [YOLODetection] {
        let sorted = dets.sorted { $0.confidence > $1.confidence }
        var keep   = [YOLODetection]()
        var used   = [Bool](repeating: false, count: sorted.count)

        for i in 0..<sorted.count {
            guard !used[i] else { continue }
            keep.append(sorted[i])
            for j in (i + 1)..<sorted.count {
                guard !used[j] else { continue }
                if iou(sorted[i], sorted[j]) > YOLO.iouThresh { used[j] = true }
            }
        }
        return keep
    }

    private func iou(_ a: YOLODetection, _ b: YOLODetection) -> Float {
        let ix1   = max(a.x1, b.x1),  iy1 = max(a.y1, b.y1)
        let ix2   = min(a.x2, b.x2),  iy2 = min(a.y2, b.y2)
        let inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
        let ua    = (a.x2 - a.x1) * (a.y2 - a.y1)
        let ub    = (b.x2 - b.x1) * (b.y2 - b.y1)
        let union = ua + ub - inter
        return union > 0 ? inter / union : 0
    }

    // MARK: - Preprocessing: Letterbox (640×640) + CLAHE on L Channel Only (LAB Color Space)

    private func buildPreprocessedImages(from image: UIImage) -> PreprocessedImages? {
        guard let sourceCG = image.cgImage else { return nil }
        let srcW = sourceCG.width, srcH = sourceCG.height
        guard srcW > 0, srcH > 0 else { return nil }

        let inputW = YOLO.inputW, inputH = YOLO.inputH
        let bpp    = 4
        let rgbCS  = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue |
                                 CGImageAlphaInfo.noneSkipFirst.rawValue  // BGRA

        // ── 1. Compute letterbox geometry (preserve aspect ratio) ───────────
        let scaleF  = min(Float(inputW) / Float(srcW), Float(inputH) / Float(srcH))
        let scaledW = Int((Float(srcW) * scaleF).rounded())
        let scaledH = Int((Float(srcH) * scaleF).rounded())
        let offX    = (inputW  - scaledW) / 2
        let offY    = (inputH  - scaledH) / 2

        let lb = LetterboxInfo(scale: scaleF,
                               padX:  Float(offX),
                               padY:  Float(offY),
                               srcW:  Float(srcW),
                               srcH:  Float(srcH))

        // ── 2. Draw source image scaled into a temp buffer ──────────────────
        var scaledBuf = [UInt8](repeating: 255, count: scaledW * scaledH * bpp)
        guard let scaledCtx = CGContext(data: &scaledBuf,
                                         width: scaledW, height: scaledH,
                                         bitsPerComponent: 8,
                                         bytesPerRow: scaledW * bpp,
                                         space: rgbCS,
                                         bitmapInfo: bitmapInfo) else { return nil }
        scaledCtx.interpolationQuality = .medium
        scaledCtx.draw(sourceCG, in: CGRect(x: 0, y: 0, width: scaledW, height: scaledH))

        // ── 3. Create 640×640 canvas filled with YOLO gray (114, 114, 114) ──
        let totalPx = inputW * inputH
        var canvas  = [UInt8](repeating: 0, count: totalPx * bpp)
        for i in 0..<totalPx {
            canvas[i * bpp + 0] = 114   // B
            canvas[i * bpp + 1] = 114   // G
            canvas[i * bpp + 2] = 114   // R
            canvas[i * bpp + 3] = 255   // A
        }

        // Copy scaled image into the canvas at (offX, offY)
        for row in 0..<scaledH {
            let dstRow = row + offY
            guard dstRow < inputH else { break }
            let srcBase = row * scaledW * bpp
            let dstBase = (dstRow * inputW + offX) * bpp
            let cols    = min(scaledW, inputW - offX) * bpp
            guard cols > 0 else { continue }
            for col in 0..<cols {
                canvas[dstBase + col] = scaledBuf[srcBase + col]
            }
        }

        // ── 4. Separate R, G, B channels (BGRA: B=+0, G=+1, R=+2) ──────────
        var rCh = [UInt8](repeating: 0, count: totalPx)
        var gCh = [UInt8](repeating: 0, count: totalPx)
        var bCh = [UInt8](repeating: 0, count: totalPx)
        for i in 0..<totalPx {
            bCh[i] = canvas[i * bpp + 0]
            gCh[i] = canvas[i * bpp + 1]
            rCh[i] = canvas[i * bpp + 2]
        }

        // ── 5. Convert RGB -> LAB color space (OpenCV COLOR_RGB2LAB equivalent) ──
        let lab = rgbToLAB(rCh: rCh, gCh: gCh, bCh: bCh, count: totalPx)

        // ── 6. Apply CLAHE ONLY to L channel (clipLimit=3.0, tileGridSize=8x8) ───
        let lClahe = applyCLAHE(pixels: lab.l, width: inputW, height: inputH, tileRows: 8, tileCols: 8, clipLimit: 3.0)

        // ── 7. Merge (L_clahe, A, B) & convert LAB back to RGB (COLOR_LAB2RGB) ───
        let rgbOut = labToRGB(lCh: lClahe, aCh: lab.a, bCh: lab.b, count: totalPx)

        // ── 8. Build CLAHE preview + model input buffer ──────────────────────
        var claheBuf = [UInt8](repeating: 255, count: totalPx * bpp)
        for i in 0..<totalPx {
            claheBuf[i * bpp + 0] = rgbOut.b[i]
            claheBuf[i * bpp + 1] = rgbOut.g[i]
            claheBuf[i * bpp + 2] = rgbOut.r[i]
            claheBuf[i * bpp + 3] = 255
        }
        guard let claheCtx = CGContext(data: &claheBuf,
                                        width: inputW, height: inputH,
                                        bitsPerComponent: 8,
                                        bytesPerRow: inputW * bpp,
                                        space: rgbCS, bitmapInfo: bitmapInfo),
              let claheCG  = claheCtx.makeImage() else { return nil }
        let clahePreview = UIImage(cgImage: claheCG, scale: 1, orientation: .up)

        print("[AcneDetector] 🧪 Preprocessed L-channel CLAHE image generated successfully (\(inputW)x\(inputH)). Debug preview available in clahePreview.")

        return PreprocessedImages(modelInput:  claheCG,
                                  clahe:       clahePreview,
                                  letterbox:   lb)
    }

    // MARK: - Color Space Conversion: RGB <-> LAB (OpenCV cv2.cvtColor compatible)

    private struct LABChannels {
        var l: [UInt8]  // [0...255], L_uint8 = L* * 2.55
        var a: [UInt8]  // [0...255], a_uint8 = a* + 128
        var b: [UInt8]  // [0...255], b_uint8 = b* + 128
    }

    /// Converts RGB pixel arrays (640x640) to OpenCV-compatible uint8 LAB channels.
    private func rgbToLAB(rCh: [UInt8], gCh: [UInt8], bCh: [UInt8], count: Int) -> LABChannels {
        var lCh = [UInt8](repeating: 0, count: count)
        var aCh = [UInt8](repeating: 0, count: count)
        var bChOut = [UInt8](repeating: 0, count: count)

        let xn = 0.950456
        let yn = 1.000000
        let zn = 1.088754
        let delta = 6.0 / 29.0
        let delta3 = delta * delta * delta

        for i in 0..<count {
            let r = Double(rCh[i]) / 255.0
            let g = Double(gCh[i]) / 255.0
            let b = Double(bCh[i]) / 255.0

            let rLin = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4) : (r / 12.92)
            let gLin = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4) : (g / 12.92)
            let bLin = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4) : (b / 12.92)

            let x = 0.412453 * rLin + 0.357580 * gLin + 0.180423 * bLin
            let y = 0.212671 * rLin + 0.715160 * gLin + 0.072169 * bLin
            let z = 0.019334 * rLin + 0.119193 * gLin + 0.950304 * bLin

            let xr = x / xn
            let yr = y / yn
            let zr = z / zn

            let fx = (xr > delta3) ? pow(xr, 1.0 / 3.0) : (7.787037 * xr + 16.0 / 116.0)
            let fy = (yr > delta3) ? pow(yr, 1.0 / 3.0) : (7.787037 * yr + 16.0 / 116.0)
            let fz = (zr > delta3) ? pow(zr, 1.0 / 3.0) : (7.787037 * zr + 16.0 / 116.0)

            let Lstar = 116.0 * fy - 16.0
            let astar = 500.0 * (fx - fy)
            let bstar = 200.0 * (fy - fz)

            lCh[i]    = UInt8(clamping: Int((Lstar * 2.55).rounded()))
            aCh[i]    = UInt8(clamping: Int((astar + 128.0).rounded()))
            bChOut[i] = UInt8(clamping: Int((bstar + 128.0).rounded()))
        }

        return LABChannels(l: lCh, a: aCh, b: bChOut)
    }

    /// Converts OpenCV-compatible uint8 LAB channels back to RGB pixel arrays.
    private func labToRGB(lCh: [UInt8], aCh: [UInt8], bCh: [UInt8], count: Int) -> (r: [UInt8], g: [UInt8], b: [UInt8]) {
        var rCh = [UInt8](repeating: 0, count: count)
        var gCh = [UInt8](repeating: 0, count: count)
        var bChOut = [UInt8](repeating: 0, count: count)

        let xn = 0.950456
        let yn = 1.000000
        let zn = 1.088754
        let delta = 6.0 / 29.0

        for i in 0..<count {
            let Lstar = Double(lCh[i]) / 2.55
            let astar = Double(aCh[i]) - 128.0
            let bstar = Double(bCh[i]) - 128.0

            let fy = (Lstar + 16.0) / 116.0
            let fx = fy + (astar / 500.0)
            let fz = fy - (bstar / 200.0)

            let xr = (fx > delta) ? (fx * fx * fx) : ((fx - 16.0 / 116.0) / 7.787037)
            let yr = (fy > delta) ? (fy * fy * fy) : ((fy - 16.0 / 116.0) / 7.787037)
            let zr = (fz > delta) ? (fz * fz * fz) : ((fz - 16.0 / 116.0) / 7.787037)

            let x = xr * xn
            let y = yr * yn
            let z = zr * zn

            let rLin =  3.2404542 * x - 1.5371385 * y - 0.4985314 * z
            let gLin = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
            let bLin =  0.0556434 * x - 0.2040259 * y + 1.0572252 * z

            let r = (rLin > 0.0031308) ? (1.055 * pow(rLin, 1.0 / 2.4) - 0.055) : (12.92 * rLin)
            let g = (gLin > 0.0031308) ? (1.055 * pow(gLin, 1.0 / 2.4) - 0.055) : (12.92 * gLin)
            let b = (bLin > 0.0031308) ? (1.055 * pow(bLin, 1.0 / 2.4) - 0.055) : (12.92 * bLin)

            rCh[i]    = UInt8(clamping: Int((r * 255.0).rounded()))
            gCh[i]    = UInt8(clamping: Int((g * 255.0).rounded()))
            bChOut[i] = UInt8(clamping: Int((b * 255.0).rounded()))
        }

        return (r: rCh, g: gCh, b: bChOut)
    }

    // MARK: - CLAHE (8×8 tile, clip=3.0, bilinear interpolation)

    private func applyCLAHE(pixels: [UInt8], width: Int, height: Int,
                             tileRows: Int = 8, tileCols: Int = 8,
                             clipLimit: Double = 3.0) -> [UInt8] {

        let tileW = max(1, width  / tileCols)
        let tileH = max(1, height / tileRows)

        var luts = [[[UInt8]]](
            repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 256), count: tileCols),
            count: tileRows
        )

        for tr in 0..<tileRows {
            for tc in 0..<tileCols {
                let x0     = tc * tileW
                let y0     = tr * tileH
                let x1     = (tc == tileCols - 1) ? width  : min(x0 + tileW, width)
                let y1     = (tr == tileRows - 1) ? height : min(y0 + tileH, height)
                let tilePx = (x1 - x0) * (y1 - y0)
                guard tilePx > 0 else { continue }

                var hist = [Int](repeating: 0, count: 256)
                for y in y0..<y1 {
                    for x in x0..<x1 { hist[Int(pixels[y * width + x])] += 1 }
                }

                let clip   = max(1, Int(clipLimit * Double(tilePx) / 256.0))
                var excess = 0
                for i in 0..<256 {
                    if hist[i] > clip { excess += hist[i] - clip; hist[i] = clip }
                }
                let bonus = excess / 256
                let rem   = excess % 256
                for i in 0..<256 { hist[i] += bonus }
                for i in 0..<rem  { hist[i] += 1     }

                var cdf = 0
                var lut = [UInt8](repeating: 0, count: 256)
                for i in 0..<256 {
                    cdf   += hist[i]
                    lut[i] = UInt8(clamping: Int((Double(cdf) * 255.0 / Double(tilePx)).rounded()))
                }
                luts[tr][tc] = lut
            }
        }

        var result = [UInt8](repeating: 0, count: pixels.count)
        for y in 0..<height {
            for x in 0..<width {
                let v  = Int(pixels[y * width + x])
                let tx = (Double(x) + 0.5) / Double(tileW) - 0.5
                let ty = (Double(y) + 0.5) / Double(tileH) - 0.5
                let tc0 = max(0, min(tileCols - 1, Int(floor(tx))))
                let tc1 = min(tileCols - 1, tc0 + 1)
                let tr0 = max(0, min(tileRows - 1, Int(floor(ty))))
                let tr1 = min(tileRows - 1, tr0 + 1)
                let xf  = max(0.0, min(1.0, tx - Double(tc0)))
                let yf  = max(0.0, min(1.0, ty - Double(tr0)))
                let out = Double(luts[tr0][tc0][v]) * (1 - xf) * (1 - yf)
                        + Double(luts[tr0][tc1][v]) *      xf  * (1 - yf)
                        + Double(luts[tr1][tc0][v]) * (1 - xf) *      yf
                        + Double(luts[tr1][tc1][v]) *      xf  *      yf
                result[y * width + x] = UInt8(clamping: Int(out.rounded()))
            }
        }
        return result
    }

    // MARK: - SkinConditionSegmenter Mask Parser (fallback)

    private func parseSegmenterMask(results: [VNObservation]?,
                                     clahe: UIImage) -> DetectionResult {

        guard let obs = results?.first as? VNPixelBufferObservation else {
            print("[AcneDetector/Segmenter] no VNPixelBufferObservation — got \(String(describing: results?.first))")
            return defaultResult(clahe: clahe)
        }

        let pb = obs.pixelBuffer
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }

        let width   = CVPixelBufferGetWidth(pb)
        let height  = CVPixelBufferGetHeight(pb)
        let format  = CVPixelBufferGetPixelFormatType(pb)
        let bpr     = CVPixelBufferGetBytesPerRow(pb)
        let totalPx = width * height

        print("[AcneDetector/Segmenter] mask \(width)×\(height) fmt=0x\(String(format:"%08X",format)) bpr=\(bpr)")

        guard totalPx > 0,
              let base = CVPixelBufferGetBaseAddress(pb) else {
            return defaultResult(clahe: clahe)
        }

        // ── Float32 single-channel (many CoreML segmentation models) ────────
        let kOneComponent32Float: OSType = 114  // 'r'
        if format == kOneComponent32Float {
            return parseSegmenterFloat(base: base, bpr: bpr,
                                        width: width, height: height, totalPx: totalPx,
                                        clahe: clahe)
        }

        // ── UInt8 4-channel (BGRA / RGBA / ARGB) ────────────────────────────
        let rOff: Int
        switch format {
        case kCVPixelFormatType_32BGRA: rOff = 2
        case kCVPixelFormatType_32RGBA: rOff = 0
        case kCVPixelFormatType_32ARGB: rOff = 1
        default:
            print("[AcneDetector/Segmenter] unknown format \(format) — channel-0 fallback")
            rOff = 0
        }

        let buf       = base.assumingMemoryBound(to: UInt8.self)
        let threshold = 10
        let gridN     = 64
        let cellW     = max(1, width  / gridN)
        let cellH     = max(1, height / gridN)

        var grid   = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var rTotal = 0.0

        for gy in 0..<gridN {
            for gx in 0..<gridN {
                var sum = 0, cnt = 0
                let yS = gy*cellH, yE = min(yS+cellH, height)
                let xS = gx*cellW, xE = min(xS+cellW, width)
                for py in yS..<yE {
                    for px in xS..<xE { sum += Int(buf[py*bpr + px*4 + rOff]); cnt += 1 }
                }
                if cnt > 0 { grid[gy][gx] = sum/cnt > threshold }
            }
        }
        for y in 0..<height {
            for x in 0..<width { rTotal += Double(buf[y*bpr + x*4 + rOff]) }
        }
        let density = rTotal / Double(totalPx)
        print("[AcneDetector/Segmenter] uint8 density=\(density)/255")

        let boxes = segmenterBoundingBoxes(grid: grid, gridN: gridN)
        return DetectionResult(
            acne:         segmenterScore(density: density, boxes: boxes),
            clahePreview: clahe
        )
    }

    private func parseSegmenterFloat(base: UnsafeMutableRawPointer,
                                      bpr: Int,
                                      width: Int, height: Int, totalPx: Int,
                                      clahe: UIImage) -> DetectionResult {
        let fbuf      = base.assumingMemoryBound(to: Float32.self)
        let floatBPR  = bpr / MemoryLayout<Float32>.size
        let threshold: Float = 0.15
        let gridN     = 64
        let cellW     = max(1, width  / gridN)
        let cellH     = max(1, height / gridN)

        var grid   = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var fTotal = 0.0

        for gy in 0..<gridN {
            for gx in 0..<gridN {
                var sum: Float = 0; var cnt = 0
                let yS = gy*cellH, yE = min(yS+cellH, height)
                let xS = gx*cellW, xE = min(xS+cellW, width)
                for py in yS..<yE {
                    for px in xS..<xE { sum += fbuf[py * floatBPR + px]; cnt += 1 }
                }
                if cnt > 0 { grid[gy][gx] = (sum / Float(cnt)) > threshold }
            }
        }
        for y in 0..<height { for x in 0..<width { fTotal += Double(fbuf[y * floatBPR + x]) } }
        let density = (fTotal / Double(totalPx)) * 255.0
        print("[AcneDetector/Segmenter] float density=\(fTotal/Double(totalPx))")

        let boxes = segmenterBoundingBoxes(grid: grid, gridN: gridN)
        return DetectionResult(
            acne:         segmenterScore(density: density, boxes: boxes),
            clahePreview: clahe
        )
    }

    private func segmenterBoundingBoxes(grid: [[Bool]], gridN: Int) -> [SkinBoundingBox] {
        var visited = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var boxes   = [SkinBoundingBox]()
        let pad     = 1.0 / Double(gridN)

        for y in 0..<gridN {
            for x in 0..<gridN {
                guard grid[y][x], !visited[y][x] else { continue }
                var q = [(x,y)]; var qi = 0
                var mnX=x, mxX=x, mnY=y, mxY=y
                visited[y][x] = true
                while qi < q.count {
                    let (cx,cy) = q[qi]; qi += 1
                    for (dx,dy) in [(-1,0),(1,0),(0,-1),(0,1)] {
                        let nx=cx+dx, ny=cy+dy
                        guard nx>=0,nx<gridN,ny>=0,ny<gridN,grid[ny][nx],!visited[ny][nx] else { continue }
                        visited[ny][nx]=true; q.append((nx,ny))
                        mnX=min(mnX,nx); mxX=max(mxX,nx); mnY=min(mnY,ny); mxY=max(mxY,ny)
                    }
                }
                guard (mxX-mnX+1)*(mxY-mnY+1) >= 3 else { continue }
                let x0 = max(0.0, Double(mnX)/Double(gridN) - pad)
                let y0 = max(0.0, Double(mnY)/Double(gridN) - pad)
                let x1 = min(1.0, Double(mxX+1)/Double(gridN) + pad)
                let y1 = min(1.0, Double(mxY+1)/Double(gridN) + pad)
                boxes.append(SkinBoundingBox(x: x0, y: y0, width: x1-x0, height: y1-y0))
            }
        }
        return boxes
    }

    private func segmenterScore(density: Double, boxes: [SkinBoundingBox]) -> ConditionScore {
        let n = density / 255.0
        let level: String
        let confidence: Double
        if n < 0.05 {
            level = "low";      confidence = (n / 0.05) * 0.35
        } else if n < 0.20 {
            level = "moderate"; confidence = 0.35 + ((n - 0.05) / 0.15) * 0.35
        } else {
            level = "high";     confidence = 0.70 + min(0.30, ((n - 0.20) / 0.30) * 0.30)
        }
        return ConditionScore(level: level,
                              confidence: max(0, min(1, confidence)),
                              density: density,
                              boundingBoxes: boxes)
    }

    private func makeScore(detections: [YOLODetection],
                           boxes: [SkinBoundingBox]) -> ConditionScore {
        guard !detections.isEmpty else {
            return ConditionScore(level: "low", confidence: 0, density: 0, boundingBoxes: [])
        }

        let totalArea = detections.reduce(0.0) {
            $0 + Double(($1.x2 - $1.x1) * ($1.y2 - $1.y1))
        }
        let confSum  = detections.reduce(0.0) { $0 + Double($1.confidence) }
        let meanConf = confSum / Double(detections.count)
        let n        = detections.count

        let level: String
        if      n <= 2 && totalArea < 0.05  { level = "low"      }
        else if n <= 7 && totalArea < 0.15  { level = "moderate" }
        else                                { level = "high"     }

        return ConditionScore(
            level:         level,
            confidence:    meanConf,
            density:       totalArea * 255,   // legacy scale
            boundingBoxes: boxes
        )
    }

    // MARK: - Utilities

    @inline(__always)
    private func sigmoid(_ x: Float) -> Float { 1.0 / (1.0 + expf(-x)) }

    private func defaultResult(clahe: UIImage? = nil) -> DetectionResult {
        DetectionResult(
            acne: ConditionScore(level: "low", confidence: 0, density: 0, boundingBoxes: []),
            clahePreview: clahe
        )
    }

    private func makeError(_ msg: String, code: Int) -> NSError {
        NSError(domain: "AcneDetection", code: code,
                userInfo: [NSLocalizedDescriptionKey: msg])
    }

    // MARK: - YOLO Instance Mask Parsing

    private func extractYOLOPolygon(det: YOLODetection,
                                    proto: MLMultiArray,
                                    lb: LetterboxInfo) -> [CGPoint]? {
        let px1 = max(0, min(159, Int(round(det.x1 * 160.0))))
        let px2 = max(0, min(159, Int(round(det.x2 * 160.0))))
        let py1 = max(0, min(159, Int(round(det.y1 * 160.0))))
        let py2 = max(0, min(159, Int(round(det.y2 * 160.0))))

        guard px2 >= px1, py2 >= py1 else { return nil }

        let pw = px2 - px1 + 1
        let ph = py2 - py1 + 1

        var grid = [[Bool]](repeating: [Bool](repeating: false, count: pw), count: ph)

        let protoPtr = proto.dataPointer.assumingMemoryBound(to: Float32.self)
        let strides = proto.strides.map { $0.intValue }

        let cStride = strides[1]
        let yStride = strides[2]
        let xStride = strides[3]

        var hasAnyMask = false

        for y in 0..<ph {
            let py = py1 + y
            for x in 0..<pw {
                let px = px1 + x
                var sum: Float = 0
                for k in 0..<32 {
                    let val = protoPtr[k * cStride + py * yStride + px * xStride]
                    sum += det.maskCoeffs[k] * val
                }
                let prob = 1.0 / (1.0 + exp(-sum))
                if prob > 0.5 {
                    grid[y][x] = true
                    hasAnyMask = true
                }
            }
        }

        if !hasAnyMask {
            return generateEllipsePolygon(det: det, lb: lb)
        }

        let contour = traceGridContour(grid: grid)
        guard !contour.isEmpty else {
            return generateEllipsePolygon(det: det, lb: lb)
        }

        let scaledW = lb.scale * lb.srcW
        let scaledH = lb.scale * lb.srcH

        return contour.map { pt in
            let gx = Double(px1) + Double(pt.x)
            let gy = Double(py1) + Double(pt.y)

            let x640 = (gx / 160.0) * Double(YOLO.inputW)
            let y640 = (gy / 160.0) * Double(YOLO.inputH)

            let x_orig = max(0.0, min(1.0, (x640 - Double(lb.padX)) / Double(scaledW)))
            let y_orig = max(0.0, min(1.0, (y640 - Double(lb.padY)) / Double(scaledH)))
            return CGPoint(x: x_orig, y: y_orig)
        }
    }

    private func generateEllipsePolygon(det: YOLODetection, lb: LetterboxInfo) -> [CGPoint] {
        let scaledW = lb.scale * lb.srcW
        let scaledH = lb.scale * lb.srcH
        let W = Double(YOLO.inputW)
        let H = Double(YOLO.inputH)

        let x1 = max(0.0, min(1.0, (Double(det.x1) * W - Double(lb.padX)) / Double(scaledW)))
        let y1 = max(0.0, min(1.0, (Double(det.y1) * H - Double(lb.padY)) / Double(scaledH)))
        let x2 = max(0.0, min(1.0, (Double(det.x2) * W - Double(lb.padX)) / Double(scaledW)))
        let y2 = max(0.0, min(1.0, (Double(det.y2) * H - Double(lb.padY)) / Double(scaledH)))

        let cx = (x1 + x2) / 2.0
        let cy = (y1 + y2) / 2.0
        let rx = (x2 - x1) / 2.0
        let ry = (y2 - y1) / 2.0

        var points = [CGPoint]()
        let steps = 16
        for i in 0..<steps {
            let theta = 2.0 * Double.pi * Double(i) / Double(steps)
            let px = cx + rx * cos(theta)
            let py = cy + ry * sin(theta)
            points.append(CGPoint(x: max(0.0, min(1.0, px)), y: max(0.0, min(1.0, py))))
        }
        return points
    }

    private func traceGridContour(grid: [[Bool]]) -> [CGPoint] {
        let h = grid.count
        guard h > 0 else { return [] }
        let w = grid[0].count
        guard w > 0 else { return [] }

        var startX = -1
        var startY = -1
        outerLoop: for y in 0..<h {
            for x in 0..<w {
                if grid[y][x] {
                    startX = x
                    startY = y
                    break outerLoop
                }
            }
        }

        guard startX != -1 else { return [] }

        var contour = [CGPoint]()
        var cx = startX
        var cy = startY
        let dx = [1, 1, 0, -1, -1, -1, 0, 1]
        let dy = [0, 1, 1, 1, 0, -1, -1, -1]

        var backtrackDir = 6
        var first = true

        while first || (cx != startX || cy != startY) {
            first = false
            contour.append(CGPoint(x: cx, y: cy))

            var foundNext = false
            for i in 0..<8 {
                let nDir = (backtrackDir + i) % 8
                let nx = cx + dx[nDir]
                let ny = cy + dy[nDir]

                if nx >= 0 && nx < w && ny >= 0 && ny < h && grid[ny][nx] {
                    cx = nx
                    cy = ny
                    backtrackDir = (nDir + 5) % 8
                    foundNext = true
                    break
                }
            }

            if !foundNext { break }
            if contour.count > 500 { break }
        }

        return contour
    }
}
