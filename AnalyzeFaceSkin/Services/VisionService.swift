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

        // Add padding around the face bounding box to include forehead, ears, and chin naturally
        let paddingX = bbox.width * 0.20 // 20% width padding on left and right
        let paddingYTop = bbox.height * 0.45 // 45% height padding on top (to include forehead & hair line)
        let paddingYBottom = bbox.height * 0.15 // 15% height padding on bottom (to include chin & neck)
        
        let minX = max(0.0, bbox.origin.x - paddingX)
        let maxX = min(1.0, bbox.origin.x + bbox.width + paddingX)
        let minY = max(0.0, bbox.origin.y - paddingYBottom)
        let maxY = min(1.0, bbox.origin.y + bbox.height + paddingYTop)
        
        let paddedBBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let faceW = paddedBBox.width * imageW
        let faceH = paddedBBox.height * imageH
        let faceX = paddedBBox.origin.x * imageW
        let faceY = (1 - paddedBBox.origin.y - paddedBBox.height) * imageH
        
        let faceRect = CGRect(x: faceX, y: faceY, width: faceW, height: faceH)

        guard let cropped = cgImage.cropping(to: faceRect) else { return nil }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }

    struct ProcessedFace {
        let croppedImage: UIImage
        let landmarks: [String: [CGPoint]]
    }
    
    func processFace(from image: UIImage, using boundingBox: CGRect? = nil) -> ProcessedFace? {
        // Normalize the image to burn the correct orientation into raw pixels
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(at: .zero)
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = normalized?.cgImage else { return nil }
        
        let imageW = CGFloat(cgImage.width)
        let imageH = CGFloat(cgImage.height)
        
        // 1. Detect face bounding box if not provided
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
        
        // 2. Add padding to include forehead, ears, chin
        let paddingX = bbox.width * 0.20
        let paddingYTop = bbox.height * 0.45
        let paddingYBottom = bbox.height * 0.15
        
        let minX = max(0.0, bbox.origin.x - paddingX)
        let maxX = min(1.0, bbox.origin.x + bbox.width + paddingX)
        let minY = max(0.0, bbox.origin.y - paddingYBottom)
        let maxY = min(1.0, bbox.origin.y + bbox.height + paddingYTop)
        
        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let faceW = cropRect.width * imageW
        let faceH = cropRect.height * imageH
        let faceX = cropRect.origin.x * imageW
        let faceY = (1 - cropRect.origin.y - cropRect.height) * imageH
        
        let faceRect = CGRect(x: faceX, y: faceY, width: faceW, height: faceH)
        guard let croppedCG = cgImage.cropping(to: faceRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCG, scale: image.scale, orientation: .up)
        
        // 3. Detect facial landmarks on original image
        let landmarkRequest = VNDetectFaceLandmarksRequest()
        landmarkRequest.revision = VNDetectFaceLandmarksRequestRevision3
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([landmarkRequest])
        
        guard let faceWithLandmarks = landmarkRequest.results?.first,
              let landmarks = faceWithLandmarks.landmarks else {
            return ProcessedFace(croppedImage: croppedImage, landmarks: [:])
        }
        
        let detectedFaceBounds = faceWithLandmarks.boundingBox
        var landmarkGroups: [String: [CGPoint]] = [:]
        
        func mapRegion(_ region: VNFaceLandmarkRegion2D?) -> [CGPoint] {
            guard let region = region else { return [] }
            let points = region.normalizedPoints
            return points.map { pt in
                // Map from face bounding box space to original image space
                let origX = detectedFaceBounds.origin.x + pt.x * detectedFaceBounds.size.width
                let origY = detectedFaceBounds.origin.y + pt.y * detectedFaceBounds.size.height
                
                // Map from original image space to cropped image space
                let cropX = (origX - cropRect.origin.x) / cropRect.width
                let cropY = (origY - cropRect.origin.y) / cropRect.height
                
                // Flip Y coordinate for SwiftUI
                return CGPoint(x: cropX, y: 1.0 - cropY)
            }
        }
        
        landmarkGroups["contour"] = mapRegion(landmarks.faceContour)
        landmarkGroups["leftEyebrow"] = mapRegion(landmarks.leftEyebrow)
        landmarkGroups["rightEyebrow"] = mapRegion(landmarks.rightEyebrow)
        landmarkGroups["leftEye"] = mapRegion(landmarks.leftEye)
        landmarkGroups["rightEye"] = mapRegion(landmarks.rightEye)
        landmarkGroups["nose"] = mapRegion(landmarks.nose)
        landmarkGroups["noseCrest"] = mapRegion(landmarks.noseCrest)
        landmarkGroups["outerLips"] = mapRegion(landmarks.outerLips)
        landmarkGroups["innerLips"] = mapRegion(landmarks.innerLips)
        
        return ProcessedFace(croppedImage: croppedImage, landmarks: landmarkGroups)
    }
}

