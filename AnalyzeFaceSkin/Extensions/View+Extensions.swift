//
//  View+Extensions.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI

extension View {
    func asImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        let size = view?.intrinsicContentSize ?? .zero
        view?.bounds = CGRect(origin: .zero, size: size)
        view?.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
}
