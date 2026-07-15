//
//  AcneWrinkleDetectionService.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 14/07/26.
//

import UIKit
import CoreML
import Vision

/// Detects acne, pores, and wrinkles using `SkinConditionSegmenter`.
///
/// The model outputs a 512×512 segmentation mask where:
///   - Red   channel → Acne    regions
///   - Green channel → Pore    regions
///   - Blue  channel → Wrinkle regions
///
/// Each channel is analysed to produce:
///   - A severity level  (low / moderate / severe)
///   - A confidence score
///   - A list of normalized bounding boxes (0..1) so the UI can draw overlays
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
        let level:        String           // "low" | "moderate" | "severe"
        let confidence:   Double           // 0..1
        let density:      Double           // mean intensity (0–255) for debugging
        let boundingBoxes: [SkinBoundingBox]
    }

    struct DetectionResult {
        let acne:     ConditionScore
        let pores:    ConditionScore
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
        let gOff: Int
        let bOff: Int
        switch format {
        case kCVPixelFormatType_32BGRA:
            bOff = 0; gOff = 1; rOff = 2
        case kCVPixelFormatType_32RGBA:
            rOff = 0; gOff = 1; bOff = 2
        case kCVPixelFormatType_32ARGB:
            rOff = 1; gOff = 2; bOff = 3
        default:
            return defaultResult()
        }

        // Threshold: pixel channel value must exceed this to count as "active"
        let threshold: Int = 30

        // ── Build 64×64 activation grids ──────────────────────────────────────
        // Downsampling reduces noise and speeds up connected-component analysis.
        let gridN = 64
        let cellW = max(1, width  / gridN)
        let cellH = max(1, height / gridN)

        var rGrid = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var gGrid = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)
        var bGrid = [[Bool]](repeating: [Bool](repeating: false, count: gridN), count: gridN)

        var rTotal: Double = 0
        var gTotal: Double = 0
        var bTotal: Double = 0

        for gy in 0..<gridN {
            for gx in 0..<gridN {
                var rSum = 0, gSum = 0, bSum = 0, count = 0
                let yStart = gy * cellH
                let xStart = gx * cellW
                let yEnd   = min(yStart + cellH, height)
                let xEnd   = min(xStart + cellW, width)
                for py in yStart..<yEnd {
                    for px in xStart..<xEnd {
                        let off = py * bytesPerRow + px * 4
                        rSum += Int(buf[off + rOff])
                        gSum += Int(buf[off + gOff])
                        bSum += Int(buf[off + bOff])
                        count += 1
                    }
                }
                if count > 0 {
                    rGrid[gy][gx] = rSum / count > threshold
                    gGrid[gy][gx] = gSum / count > threshold
                    bGrid[gy][gx] = bSum / count > threshold
                }
            }
        }

        // Global channel means (for severity scoring)
        for y in 0..<height {
            for x in 0..<width {
                let off = y * bytesPerRow + x * 4
                rTotal += Double(buf[off + rOff])
                gTotal += Double(buf[off + gOff])
                bTotal += Double(buf[off + bOff])
            }
        }
        let acneDensity    = rTotal / Double(totalPx)
        let poreDensity    = gTotal / Double(totalPx)
        let wrinkleDensity = bTotal / Double(totalPx)

        // ── Extract bounding boxes via connected components ────────────────────
        let acneBBoxes    = connectedComponents(grid: rGrid, gridN: gridN)
        let poreBBoxes    = connectedComponents(grid: gGrid, gridN: gridN)
        let wrinkleBBoxes = connectedComponents(grid: bGrid, gridN: gridN)

        return DetectionResult(
            acne:     makeScore(density: acneDensity,    boxes: acneBBoxes),
            pores:    makeScore(density: poreDensity,    boxes: poreBBoxes),
            wrinkles: makeScore(density: wrinkleDensity, boxes: wrinkleBBoxes)
        )
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
                                             width: x1 - x0, height: y1 - y0))
            }
        }
        return boxes
    }

    // MARK: - Severity scoring

    private func makeScore(density: Double, boxes: [SkinBoundingBox]) -> ConditionScore {
        let normalized = density / 255.0
        let level: String
        let confidence: Double
        switch normalized {
        case 0..<0.05:
            level = "low";      confidence = max(0, 1.0 - normalized / 0.05)
        case 0.05..<0.20:
            level = "moderate"; confidence = 0.6 + (normalized - 0.05) / 0.15 * 0.3
        default:
            level = "severe";   confidence = min(1.0, 0.7 + (normalized - 0.20) / 0.80 * 0.3)
        }
        return ConditionScore(
            level: level,
            confidence: max(0, min(1, confidence)),
            density: density,
            boundingBoxes: boxes
        )
    }

    private func defaultResult() -> DetectionResult {
        let s = ConditionScore(level: "low", confidence: 0.5, density: 0, boundingBoxes: [])
        return DetectionResult(acne: s, pores: s, wrinkles: s)
    }
}
