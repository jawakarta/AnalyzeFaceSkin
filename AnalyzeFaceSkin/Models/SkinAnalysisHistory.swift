//
//  SkinAnalysisHistory.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 14/07/26.
//

import Foundation
import SwiftData
import UIKit

@Model
final class SkinAnalysisHistory {
    @Attribute(.unique) var id: UUID
    var skinType: String
    var skinTypeConfidence: Double
    var acneSpotCount: Int = 0
    var acneBoundingBoxesData: Data? = nil
    var imageData: Data?
    var createdAt: Date

    init(skinType: String, skinTypeConfidence: Double, acneSpotCount: Int = 0, acneBoundingBoxes: [SkinBoundingBox] = [], imageData: Data?) {
        self.id = UUID()
        self.skinType = skinType
        self.skinTypeConfidence = skinTypeConfidence
        self.acneSpotCount = acneSpotCount
        self.imageData = imageData
        self.createdAt = Date()
        self.acneBoundingBoxes = acneBoundingBoxes
    }

    var acneBoundingBoxes: [SkinBoundingBox] {
        get {
            guard let data = acneBoundingBoxesData,
                  let boxes = try? JSONDecoder().decode([SkinBoundingBox].self, from: data) else {
                return []
            }
            return boxes
        }
        set {
            acneBoundingBoxesData = try? JSONEncoder().encode(newValue)
        }
    }

    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
