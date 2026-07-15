//
//  SkinAnalysisService.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit

class SkinAnalysisService {
    private lazy var skinTypeService  = SkinTypeClassifierService()
    private lazy var conditionService = AcneWrinkleDetectionService()

    func analyze(image: UIImage,
                 completion: @escaping (Result<SkinAnalysisResult, Error>) -> Void) {

        skinTypeService.classify(image: image) { [weak self] typeResult in
            guard let self = self else { return }

            var skinTypeData: (type: String, confidence: Double)?
            var captureError: Error?

            switch typeResult {
            case .success(let d): skinTypeData = d
            case .failure(let e): captureError = e
            }

            self.conditionService.detect(image: image) { detectionResult in
                var conditionData: AcneWrinkleDetectionService.DetectionResult?

                switch detectionResult {
                case .success(let d): conditionData = d
                case .failure(let e): if captureError == nil { captureError = e }
                }

                DispatchQueue.main.async {
                    if let error = captureError {
                        completion(.failure(error)); return
                    }

                    let result = SkinAnalysisResult(
                        skinType:           skinTypeData?.type,
                        skinTypeConfidence: skinTypeData?.confidence,

                        acneLevel:         conditionData?.acne.level,
                        acneConfidence:    conditionData?.acne.confidence,
                        acneBoundingBoxes: conditionData?.acne.boundingBoxes ?? [],

                        wrinkleLevel:         conditionData?.wrinkles.level,
                        wrinkleConfidence:    conditionData?.wrinkles.confidence,
                        wrinkleBoundingBoxes: conditionData?.wrinkles.boundingBoxes ?? []
                    )
                    completion(.success(result))
                }
            }
        }
    }
}
