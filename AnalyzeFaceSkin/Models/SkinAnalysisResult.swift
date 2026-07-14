//
//  SkinAnalysisResult.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import Foundation

struct SkinAnalysisResult: Codable, Equatable {
    // Model 1: Skin Type
    let skinType: String?
    let skinTypeConfidence: Double?
    
    // Future expansion for Models 2 & 3
    // var conditions: [String: Double]?
    // var overallScore: Double?
}
