//
//  VisionService.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import Vision
import UIKit

class VisionService {
    private let faceDetectionRequest: VNDetectFaceRectanglesRequest
    private let sequenceHandler = VNSequenceRequestHandler()

    init() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest()
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
    }

    func detectFace(in sampleBuffer: CMSampleBuffer) -> FaceState {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return FaceState()
        }

        var faceState = FaceState()

        do {
            try sequenceHandler.perform([faceDetectionRequest], on: pixelBuffer, orientation: .up)
        } catch {
            return faceState
        }

        guard let result = faceDetectionRequest.results?.first else {
            return faceState
        }

        faceState.isDetected = true
        faceState.boundingBox = result.boundingBox
        faceState.pitch = result.pitch
        faceState.roll = result.roll
        faceState.yaw = result.yaw

        return faceState
    }

    func cropFace(from image: UIImage, using boundingBox: CGRect? = nil) -> UIImage? {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(at: .zero)
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = normalized?.cgImage else { return nil }

        let imageW = CGFloat(cgImage.width)
        let imageH = CGFloat(cgImage.height)

        let bbox: CGRect
        if let boundingBox = boundingBox {
            bbox = boundingBox
        } else {
            let request = VNDetectFaceRectanglesRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            guard let face = request.results?.first else { return nil }
            bbox = face.boundingBox
        }

        let faceW = bbox.width * imageW
        let faceH = bbox.height * imageH
        let faceX = bbox.origin.x * imageW
        let faceY = (1 - bbox.origin.y - bbox.height) * imageH

        let faceRect = CGRect(x: faceX, y: faceY, width: faceW, height: faceH)

        guard let cropped = cgImage.cropping(to: faceRect) else { return nil }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }
}
