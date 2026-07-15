//
//  SkinAnalysisResult.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import Foundation
import CoreGraphics

// MARK: - Bounding Box

/// A normalized bounding box (0.0 – 1.0 in both axes) from the segmentation mask.
struct SkinBoundingBox: Codable, Equatable {
    let x:      Double  // origin x, left edge (0 = left of image)
    let y:      Double  // origin y, top  edge (0 = top  of image)
    let width:  Double
    let height: Double

    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}

// MARK: - Analysis Result

struct SkinAnalysisResult: Codable, Equatable {

    // MARK: Skin Type  (SkinTypeClassifier)
    let skinType:           String?
    let skinTypeConfidence: Double?

    // MARK: Conditions (SkinConditionSegmenter)

    let acneLevel:      String?
    let acneConfidence: Double?
    let acneBoundingBoxes: [SkinBoundingBox]

    let wrinkleLevel:      String?
    let wrinkleConfidence: Double?
    let wrinkleBoundingBoxes: [SkinBoundingBox]
}
