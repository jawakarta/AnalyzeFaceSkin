//
//  CameraViewModel.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import Combine
import CoreMedia

class CameraViewModel: ObservableObject {
    @Published var faceState = FaceState()
    @Published var captureState: CaptureState = .idle
    @Published var guideText = "Move your face into frame"
    @Published var ovalColor: Color = .gray
    @Published var captureProgress: Double = 0
    @Published var permissionDenied = false
    @Published var lightingCondition: LightingCondition = .unknown
    @Published var isFlashOn = false
    @Published var capturedFaceLandmarks: [String: [CGPoint]] = [:]
    @Published var showNoFaceAlert = false
    @Published var analysisResult: SkinAnalysisResult? = nil
    @Published var isAnalyzing = false
    @Published var analysisError: String? = nil
    @Published var showAnalysisErrorAlert = false
    @Published var clahePreview: UIImage? = nil

    let cameraService = CameraService()
    private let skinAnalysisService = SkinAnalysisService()
    private let visionService = VisionService()
    private let voiceService = VoiceGuideService()
    private let photoService = PhotoLibraryService()

    private var stabilityTimer: Timer?
    private var stabilityStartTime: Date?
    private var isConfigured = false
    private var lastFaceBoundingBox: CGRect?
    private var captureBoundingBox: CGRect?

    var capturedImage: UIImage?

    func setup() {
        guard !isConfigured else { return }
        isConfigured = true
        PermissionService.requestCameraPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.cameraService.delegate = self
                self.cameraService.start()
            } else {
                self.permissionDenied = true
            }
        }
    }

    func capturePhoto() {
        // Only allow capturing if a face is detected in the preview frame
        guard faceState.isDetected else {
            print("Capture rejected: No face detected in preview")
            return
        }
        
        guard case .capturing = captureState else {
            captureState = .capturing
            captureBoundingBox = lastFaceBoundingBox
            cameraService.capturePhoto()
            return
        }
    }

    func importPhoto(from image: UIImage) {
        if let processed = visionService.processFace(from: image) {
            capturedImage = processed.croppedImage
            capturedFaceLandmarks = processed.landmarks
            captureState = .captured(processed.croppedImage)
            cameraService.stop()
        } else {
            showNoFaceAlert = true
            reset()
        }
    }

    func savePhoto() {
        guard let image = capturedImage else { return }
        photoService.save(image)
    }

    func startScanning() {
        guard let image = capturedImage else { return }
        captureState = .scanning(image)
        cameraService.stop()
        
        isAnalyzing = true
        analysisResult = nil
        analysisError = nil
        clahePreview = nil
        
        let startTime = Date()
        skinAnalysisService.analyze(image: image) { [weak self] result in
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDuration: TimeInterval = 3.0
            let delay = max(0, minimumDuration - elapsed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self?.isAnalyzing = false
                switch result {
                case .success(let output):
                    self?.analysisResult = output.result
                    self?.clahePreview = output.clahePreview
                    self?.captureState = .result(image, output.result)
                case .failure(let error):
                    print("Skin analysis failed: \(error.localizedDescription)")
                    self?.analysisError = error.localizedDescription
                    self?.showAnalysisErrorAlert = true
                    self?.reset()
                }
            }
        }
    }

    func reset() {
        capturedImage = nil
        capturedFaceLandmarks = [:]
        captureState = .idle
        stabilityStartTime = nil
        captureProgress = 0
        captureBoundingBox = nil
        lastFaceBoundingBox = nil
        stopStabilityTimer()
        analysisResult = nil
        isAnalyzing = false
        clahePreview = nil
        cameraService.start()
    }

    func toggleFlash() {
        isFlashOn.toggle()
        if cameraService.isTorchAvailable {
            cameraService.toggleTorch()
        } else {
            UIScreen.main.brightness = isFlashOn ? 1.0 : 0.5
        }
    }

    func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        photoService.requestAuthorization(completion: completion)
    }

    private func updateGuideText() {
        let text: String
        if lightingCondition == .lowLight {
            text = "Too dark, move to brighter area"
        } else if lightingCondition == .tooBright {
            text = "Too bright, move to softer light"
        } else {
            text = FaceAlignmentHelpers.determineGuideText(from: faceState)
        }
        guard guideText != text else { return }
        guideText = text
        voiceService.speak(text)
    }

    private func updateOvalColor() {
        if lightingCondition != .good {
            ovalColor = .orange
        } else if !faceState.isDetected {
            ovalColor = .gray
        } else if faceState.isAligned {
            ovalColor = .green
        } else {
            ovalColor = .yellow
        }
    }

    private func handleStability() {
        if faceState.isAligned {
            if stabilityStartTime == nil {
                stabilityStartTime = Date()
                startStabilityTimer()
            }
        } else {
            stabilityStartTime = nil
            captureProgress = 0
            stopStabilityTimer()
        }
    }

    private func startStabilityTimer() {
        stopStabilityTimer()
        stabilityTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.stabilityStartTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            self.captureProgress = min(elapsed / FaceAlignmentConstants.stabilityDuration, 1.0)
            if elapsed >= FaceAlignmentConstants.stabilityDuration {
                self.stopStabilityTimer()
                self.capturePhoto()
            }
        }
    }

    private func stopStabilityTimer() {
        stabilityTimer?.invalidate()
        stabilityTimer = nil
    }

    deinit {
        stopStabilityTimer()
    }
}

extension CameraViewModel: CameraServiceDelegate {
    func cameraService(_ service: CameraService, didUpdateFrame sampleBuffer: CMSampleBuffer) {
        // Only analyze frames and play voice guides when in idle scanning phase
        guard captureState == .idle else { return }
        
        let state = visionService.detectFace(in: sampleBuffer)
        var mutableState = state
        if state.isDetected {
            mutableState.isCentered = FaceAlignmentHelpers.isCentered(state.boundingBox)
            mutableState.isValidDistance = FaceAlignmentHelpers.isValidDistance(state.boundingBox)
            mutableState.isValidRotation = FaceAlignmentHelpers.isValidRotation(
                pitch: state.pitch, roll: state.roll, yaw: state.yaw
            )
        }
        DispatchQueue.main.async {
            self.faceState = mutableState
            let prevLighting = self.lightingCondition
            self.lightingCondition = self.cameraService.lightingCondition
            if mutableState.isDetected {
                self.lastFaceBoundingBox = mutableState.boundingBox
            }
            if self.isFlashOn && prevLighting == .lowLight && self.lightingCondition != .lowLight {
                self.isFlashOn = false
                if self.cameraService.isTorchAvailable {
                    self.cameraService.toggleTorch()
                } else {
                    UIScreen.main.brightness = 0.5
                }
            }
            self.updateOvalColor()
            self.updateGuideText()
            if self.lightingCondition == .good {
                self.handleStability()
            }
        }
    }

    func cameraService(_ service: CameraService, didCapturePhoto image: UIImage, previewImage: UIImage?) {
        let cropSource = previewImage ?? image
        if let processed = visionService.processFace(from: cropSource, using: captureBoundingBox) {
            captureBoundingBox = nil
            capturedImage = processed.croppedImage
            capturedFaceLandmarks = processed.landmarks
            voiceService.speak("Perfect")
            captureState = .captured(processed.croppedImage)
        } else {
            captureBoundingBox = nil
            showNoFaceAlert = true
            reset()
        }
        stopStabilityTimer()
    }

    func cameraService(_ service: CameraService, didFailWith error: Error) {
        print("Camera error: \(error.localizedDescription)")
    }
}
