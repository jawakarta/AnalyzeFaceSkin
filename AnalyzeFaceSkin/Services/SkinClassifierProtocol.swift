//
//  SkinClassifierProtocol.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit

protocol SkinClassifier {
    associatedtype Output
    func classify(image: UIImage, completion: @escaping (Result<Output, Error>) -> Void)
}
