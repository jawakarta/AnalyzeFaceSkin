//
//  SkinTypeClassifierService.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit
import CoreML

/// Classifies skin type as dry / normal / oily using `SkinTypeClassifier`.
/// Input : MLMultiArray [1, 3, 224, 224] (ImageNet-normalised float32)
/// Output: MLMultiArray [1, 3] → softmax → labels ["dry", "normal", "oily"]
class SkinTypeClassifierService: SkinClassifier {
    typealias Output = (type: String, confidence: Double)

    private var classifier: SkinTypeClassifier? = {
        do {
            let model = try SkinTypeClassifier(configuration: MLModelConfiguration())
            print("SkinTypeClassifier model loaded successfully")
            return model
        } catch {
            print("Failed to load SkinTypeClassifier: \(error.localizedDescription)")
            return nil
        }
    }()

    func classify(image: UIImage, completion: @escaping (Result<Output, Error>) -> Void) {
        guard let classifier = classifier else {
            completion(.failure(NSError(
                domain: "SkinTypeClassifier",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]
            )))
            return
        }

        guard let inputMultiArray = MLImageProcessor.makeMultiArray(from: image) else {
            completion(.failure(NSError(
                domain: "SkinTypeClassifier",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to multi-array input"]
            )))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Use the underlying MLModel.prediction(from:) which accepts any MLFeatureProvider,
                // bypassing the generated wrapper that only accepts SkinTypeClassifierInput.
                let featureProvider = try MLDictionaryFeatureProvider(
                    dictionary: ["input": MLFeatureValue(multiArray: inputMultiArray)]
                )
                let outputProvider = try classifier.model.prediction(from: featureProvider)
                guard let outputMultiArray = outputProvider.featureValue(for: "output")?.multiArrayValue else {
                    throw NSError(
                        domain: "SkinTypeClassifier",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Model output 'output' missing or wrong type"]
                    )
                }
                let result = self.processPrediction(outputMultiArray)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func processPrediction(_ output: MLMultiArray) -> Output {
        guard output.count >= 3 else {
            print("SkinTypeClassifier: unexpected output count \(output.count), expected 3")
            return (type: "normal", confidence: 0.0)
        }

        var values = [Float]()
        for i in 0..<3 {
            values.append(output[i].floatValue)
        }

        let probabilities = softmax(values)
        let labels = ["dry", "normal", "oily"]

        let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 1
        return (type: labels[maxIndex], confidence: Double(probabilities[maxIndex]))
    }

    private func softmax(_ values: [Float]) -> [Float] {
        let maxVal = values.max() ?? 0.0
        let exps = values.map { exp($0 - maxVal) }
        let sumExps = exps.reduce(0.0, +)
        return exps.map { $0 / sumExps }
    }
}
