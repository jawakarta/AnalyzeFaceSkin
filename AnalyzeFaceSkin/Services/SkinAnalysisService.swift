//
//  SkinAnalysisService.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit

class SkinAnalysisService {
    private let skinTypeService = SkinTypeClassifierService()
    
    // Future models (2 & 3 & 4):
    // private let skinAcneService = SkinAcneClassifierService()
    // private let skinWrinklesPoresService = SkinWrinklesPoresClassifierService()
    
    func analyze(image: UIImage, completion: @escaping (Result<SkinAnalysisResult, Error>) -> Void) {
        // Currently, only run skinTypeService.
        // In the future, run multiple services in parallel (e.g. using DispatchGroup or TaskGroup).
        skinTypeService.classify(image: image) { result in
            switch result {
            case .success(let typeData):
                let analysisResult = SkinAnalysisResult(
                    skinType: typeData.type,
                    skinTypeConfidence: typeData.confidence
                )
                completion(.success(analysisResult))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
