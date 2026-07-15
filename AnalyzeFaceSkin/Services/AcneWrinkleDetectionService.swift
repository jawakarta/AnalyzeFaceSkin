//
//  AcneWrinkleDetectionService.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 14/07/26.
//

import UIKit
import CoreML
import Vision

/// Detects acne and wrinkles using `SkinConditionSegmenter`.
///
/// The model outputs a 512×512 segmentation mask where:
///   - Red   channel → Acne    regions
///   - Blue  channel → Wrinkle regions
///
/// Each channel is analysed to produce:
///   - A severity level  (low / moderate / high)
///   - A confidence score (average of detected bounding box confidences)
///   - A list of normalized bounding boxes with individual confidences
class AcneWrinkleDetectionService {

    // MARK: - Model

    private var visionModel: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            let segmenter = try SkinConditionSegmenter(configuration: config)
            let vm = try VNCoreMLModel(for: segmenter.model)
            print("SkinConditionSegmenter loaded successfully")
            return vm
        } catch {
            print("Failed to load SkinConditionSegmenter: \(error.localizedDescription)")
            return nil
        }
    }()

    // MARK: - Public types

    struct ConditionScore {
        let level:        String
        let confidence:   Double           // average of detected bounding box confidences (0..1)
        let density:      Double           // mean intensity (0–255) for debugging
        let boundingBoxes: [SkinBoundingBox]
    }

    struct DetectionResult {
        let acne:     ConditionScore
        let wrinkles: ConditionScore
    }

    // MARK: - Public API

    func detect(image: UIImage,
                completion: @escaping (Result<DetectionResult, Error>) -> Void) {

        guard let visionModel = visionModel else {
            completion(.failure(NSError(domain: "AcneWrinkleDetection", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])))
            return
        }
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "AcneWrinkleDetection", code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"])))
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { [weak self] req, error in
            guard let self = self else { return }
            if let error = error { completion(.failure(error)); return }
            let result = self.parseMask(from: req.results)
            completion(.success(result))
        }
        request.imageCropAndScaleOption = .scaleFill

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Mask parsing

    private func parseMask(from results: [VNObservation]?) -> DetectionResult {
        guard let observation = results?.first as? VNPixelBufferObservation else {
            return defaultResult()
        }

        let pixelBuffer = observation.pixelBuffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width      = CVPixelBufferGetWidth(pixelBuffer)
        let height     = CVPixelBufferGetHeight(pixelBuffer)
        let format     = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let totalPx    = width * height
        guard totalPx > 0 else { return defaultResult() }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return defaultResult() }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buf = base.assumingMemoryBound(to: UInt8.self)

        // Channel byte-offsets depend on pixel format
        let rOff: Int
        let bOff: Int
        switch format {
        case kCVPixelFormatType_32BGRA:
            bOff = 0; rOff = 2
        case kCVPixelFormatType_32RGBA:
            rOff = 0; bOff = 2
        case kCVPixelFormatType_32ARGB:
            rOff = 1; bOff = 3
        default:
            return defaultResult()
        }

        // Threshold: pixel channel value must exceed this to count as "active"
        let threshold: Int = 30

        // ── Build 64×64 activation grids ──────────────────────────────────────
        let gridN = 64
        let cellW = max(1, width  / gridN)
        let cellH = max(1, height / gridN)

        var rGrid = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var bGrid = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)

        var rTotal: Double = 0
        var bTotal: Double = 0

        for gy in 0..<gridN {
            for gx in 0..<gridN {
                var rSum = 0, bSum = 0, count = 0
                let yStart = gy * cellH
                let xStart = gx * cellW
                let yEnd   = min(yStart + cellH, height)
                let xEnd   = min(xStart + cellW, width)
                for py in yStart..<yEnd {
                    for px in xStart..<xEnd {
                        let off = py * bytesPerRow + px * 4
                        rSum += Int(buf[off + rOff])
                        bSum += Int(buf[off + bOff])
                        count += 1
                    }
                }
                if count > 0 {
                    rGrid[gy][gx] = rSum / count > threshold
                    bGrid[gy][gx] = bSum / count > threshold
                }
            }
        }

        // Global channel means (for severity scoring)
        for y in 0..<height {
            for x in 0..<width {
                let off = y * bytesPerRow + x * 4
                rTotal += Double(buf[off + rOff])
                bTotal += Double(buf[off + bOff])
            }
        }
        let acneDensity    = rTotal / Double(totalPx)
        let wrinkleDensity = bTotal / Double(totalPx)

        // ── Extract bounding boxes via connected components ────────────────────
        let rawAcneBBoxes    = connectedComponents(grid: rGrid, gridN: gridN)
        let rawWrinkleBBoxes = connectedComponents(grid: bGrid, gridN: gridN)

        // Calculate actual confidence for each individual box by querying the raw mask buffer
        print("====== SKIN SCAN ANALYSIS LOG ======")
        print("--- ACNE DETECTIONS ---")
        let acneBBoxes = rawAcneBBoxes.enumerated().map { (index, box) -> SkinBoundingBox in
            let intensity = self.averageIntensity(in: box, width: width, height: height, bytesPerRow: bytesPerRow, buf: buf, channelOff: rOff)
            let conf = max(0.3, min(1.0, intensity / 255.0))
            print("Acne Box \(index + 1): x=\(String(format: "%.2f", box.x)), y=\(String(format: "%.2f", box.y)), width=\(String(format: "%.2f", box.width)), height=\(String(format: "%.2f", box.height)) | avgIntensity=\(String(format: "%.1f", intensity)) | confidence=\(String(format: "%.0f%%", conf * 100))")
            return SkinBoundingBox(x: box.x, y: box.y, width: box.width, height: box.height, confidence: conf)
        }

        print("--- WRINKLE DETECTIONS ---")
        let wrinkleBBoxes = rawWrinkleBBoxes.enumerated().map { (index, box) -> SkinBoundingBox in
            let intensity = self.averageIntensity(in: box, width: width, height: height, bytesPerRow: bytesPerRow, buf: buf, channelOff: bOff)
            let conf = max(0.3, min(1.0, intensity / 255.0))
            print("Wrinkle Box \(index + 1): x=\(String(format: "%.2f", box.x)), y=\(String(format: "%.2f", box.y)), width=\(String(format: "%.2f", box.width)), height=\(String(format: "%.2f", box.height)) | avgIntensity=\(String(format: "%.1f", intensity)) | confidence=\(String(format: "%.0f%%", conf * 100))")
            return SkinBoundingBox(x: box.x, y: box.y, width: box.width, height: box.height, confidence: conf)
        }

        // Overall confidence is the average of all bounding boxes' individual confidences
        let avgAcneConf = acneBBoxes.isEmpty
            ? 0.0
            : acneBBoxes.reduce(0.0, { $0 + $1.confidence }) / Double(acneBBoxes.count)
        print(">> Average Acne Confidence: \(String(format: "%.0f%%", avgAcneConf * 100)) (Total: \(acneBBoxes.count) regions)")

        let avgWrinkleConf = wrinkleBBoxes.isEmpty
            ? 0.0
            : wrinkleBBoxes.reduce(0.0, { $0 + $1.confidence }) / Double(wrinkleBBoxes.count)
        print(">> Average Wrinkle Confidence: \(String(format: "%.0f%%", avgWrinkleConf * 100)) (Total: \(wrinkleBBoxes.count) regions)")
        print("====================================")

        return DetectionResult(
            acne:     makeScore(density: acneDensity,    boxes: acneBBoxes,    avgBoxConf: avgAcneConf),
            wrinkles: makeScore(density: wrinkleDensity, boxes: wrinkleBBoxes, avgBoxConf: avgWrinkleConf)
        )
    }

    // MARK: - Helper to calculate average intensity inside a normalized bounding box

    private func averageIntensity(
        in rect: SkinBoundingBox,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        buf: UnsafePointer<UInt8>,
        channelOff: Int
    ) -> Double {
        let xStart = max(0, Int(rect.x * Double(width)))
        let yStart = max(0, Int(rect.y * Double(height)))
        let xEnd   = min(width, xStart + max(1, Int(rect.width * Double(width))))
        let yEnd   = min(height, yStart + max(1, Int(rect.height * Double(height))))

        var sum = 0
        var count = 0

        for y in yStart..<yEnd {
            for x in xStart..<xEnd {
                let off = y * bytesPerRow + x * 4
                sum += Int(buf[off + channelOff])
                count += 1
            }
        }

        guard count > 0 else { return 0.0 }
        return Double(sum) / Double(count)
    }

    // MARK: - Connected-component analysis (BFS on NxN grid)

    /// Returns a list of normalized CGRects (0..1) for each distinct blob in the grid.
    private func connectedComponents(grid: [[Bool]], gridN: Int) -> [SkinBoundingBox] {
        var visited = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var boxes: [SkinBoundingBox] = []

        for y in 0..<gridN {
            for x in 0..<gridN {
                guard grid[y][x], !visited[y][x] else { continue }

                // BFS
                var queue  = [(x, y)]
                var qi     = 0
                var minX = x, maxX = x, minY = y, maxY = y
                visited[y][x] = true

                while qi < queue.count {
                    let (cx, cy) = queue[qi]; qi += 1
                    for (dx, dy) in [(-1,0),(1,0),(0,-1),(0,1)] {
                        let nx = cx + dx, ny = cy + dy
                        guard nx >= 0, nx < gridN, ny >= 0, ny < gridN,
                              grid[ny][nx], !visited[ny][nx] else { continue }
                        visited[ny][nx] = true
                        queue.append((nx, ny))
                        minX = min(minX, nx); maxX = max(maxX, nx)
                        minY = min(minY, ny); maxY = max(maxY, ny)
                    }
                }

                // Ignore single-cell noise
                let area = (maxX - minX + 1) * (maxY - minY + 1)
                guard area >= 3 else { continue }

                // Small padding so boxes feel less tight
                let pad = 1.0 / Double(gridN)
                let x0 = max(0.0, Double(minX) / Double(gridN) - pad)
                let y0 = max(0.0, Double(minY) / Double(gridN) - pad)
                let x1 = min(1.0, Double(maxX + 1) / Double(gridN) + pad)
                let y1 = min(1.0, Double(maxY + 1) / Double(gridN) + pad)

                boxes.append(SkinBoundingBox(x: x0, y: y0,
                                             width: x1 - x0, height: y1 - y0,
                                             confidence: 0.0))
            }
        }
        return boxes
    }

    // MARK: - Severity scoring

    private func makeScore(density: Double, boxes: [SkinBoundingBox], avgBoxConf: Double) -> ConditionScore {
        let normalized = density / 255.0
        let level: String
        
        if normalized < 0.05 {
            level = "low"
        } else if normalized < 0.20 {
            level = "moderate"
        } else {
            level = "high"
        }
        
        return ConditionScore(
            level: level,
            confidence: avgBoxConf,
            density: density,
            boundingBoxes: boxes
        )
    }

    private func defaultResult() -> DetectionResult {
        let s = ConditionScore(level: "low", confidence: 0.5, density: 0, boundingBoxes: [])
        return DetectionResult(acne: s, wrinkles: s)
    }
}
