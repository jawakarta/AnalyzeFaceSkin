//
//  SkinTypeClassifierService.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit
import CoreML

class SkinTypeClassifierService: SkinClassifier {
    typealias Output = (type: String, confidence: Double)
    
    private var classifier: SkinTypeClassifier?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let configuration = MLModelConfiguration()
            self.classifier = try SkinTypeClassifier(configuration: configuration)
            print("SkinTypeClassifier model loaded successfully")
        } catch {
            print("Failed to load SkinTypeClassifier model: \(error.localizedDescription) - Full error: \(error)")
        }
    }
    
    func classify(image: UIImage, completion: @escaping (Result<Output, Error>) -> Void) {
        guard let classifier = classifier else {
            let error = NSError(
                domain: "SkinTypeClassifier",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Model not loaded"]
            )
            completion(.failure(error))
            return
        }
        
        guard let inputMultiArray = MLImageProcessor.makeMultiArray(from: image) else {
            let error = NSError(
                domain: "SkinTypeClassifier",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to multi-array input"]
            )
            completion(.failure(error))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try classifier.prediction(input: inputMultiArray)
                let result = self.processPrediction(output.output)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func processPrediction(_ output: MLMultiArray) -> Output {
        var values = [Float]()
        for i in 0..<3 {
            let index = [0, i] as [NSNumber]
            values.append(output[index].floatValue)
        }
        
        let probabilities = softmax(values)
        let labels = ["dry", "normal", "oily"]
        
        let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 1
        let type = labels[maxIndex]
        let confidence = Double(probabilities[maxIndex])
        
        return (type: type, confidence: confidence)
    }
    
    private func softmax(_ values: [Float]) -> [Float] {
        let maxVal = values.max() ?? 0.0
        let exps = values.map { exp($0 - maxVal) }
        let sumExps = exps.reduce(0.0, +)
        return exps.map { $0 / sumExps }
    }
}
