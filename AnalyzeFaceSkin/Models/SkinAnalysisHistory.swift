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
    var imageData: Data?
    var createdAt: Date

    init(skinType: String, skinTypeConfidence: Double, imageData: Data?) {
        self.id = UUID()
        self.skinType = skinType
        self.skinTypeConfidence = skinTypeConfidence
        self.imageData = imageData
        self.createdAt = Date()
    }

    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
