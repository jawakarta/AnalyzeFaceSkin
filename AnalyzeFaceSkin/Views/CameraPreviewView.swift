//
//  CameraPreviewView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import AVFoundation

class PreviewView: UIView {
    let cameraService: CameraService

    init(cameraService: CameraService) {
        self.cameraService = cameraService
        super.init(frame: .zero)
        backgroundColor = .black
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let previewLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer else {
            return
        }
        previewLayer.frame = bounds
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        PreviewView(cameraService: cameraService)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.setNeedsLayout()
    }
}
