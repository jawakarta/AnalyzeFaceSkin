import AVFoundation
import UIKit

protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didUpdateFrame sampleBuffer: CMSampleBuffer)
    func cameraService(_ service: CameraService, didCapturePhoto image: UIImage, previewImage: UIImage?)
    func cameraService(_ service: CameraService, didFailWith error: Error)
}

enum LightingCondition {
    case unknown
    case good
    case lowLight
    case tooBright
}

class CameraService: NSObject {
    weak var delegate: CameraServiceDelegate?
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "camera.processing")
    private var frontCamera: AVCaptureDevice?

    var lightingCondition: LightingCondition {
        guard let device = frontCamera, device.isConnected else { return .unknown }
        let iso = device.iso
        let duration = CMTimeGetSeconds(device.exposureDuration)
        let score = iso * Float(duration)
        if score > 8 { return .lowLight }
        if score < 0.3 { return .tooBright }
        return .good
    }

    var isTorchAvailable: Bool {
        frontCamera?.isTorchAvailable ?? false
    }

    func toggleTorch() {
        guard let device = frontCamera, device.isTorchAvailable else { return }
        try? device.lockForConfiguration()
        device.torchMode = device.isTorchActive ? .off : .on
        device.unlockForConfiguration()
    }

    private var photoSettings: AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        return settings
    }

    func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let frontCamera = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front
            ), let input = try? AVCaptureDeviceInput(device: frontCamera),
                  self.session.canAddInput(input) else {
                self.delegate?.cameraService(self, didFailWith: CameraError.setupFailed)
                self.session.commitConfiguration()
                return
            }
            self.frontCamera = frontCamera
            self.session.addInput(input)

            guard self.session.canAddOutput(self.photoOutput) else {
                self.delegate?.cameraService(self, didFailWith: CameraError.setupFailed)
                self.session.commitConfiguration()
                return
            }
            self.photoOutput.isHighResolutionCaptureEnabled = true
            self.session.addOutput(self.photoOutput)

            guard self.session.canAddOutput(self.videoOutput) else {
                self.delegate?.cameraService(self, didFailWith: CameraError.setupFailed)
                self.session.commitConfiguration()
                return
            }
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.processingQueue)
            self.session.addOutput(self.videoOutput)

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            self.session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    func stop() {
        session.stopRunning()
    }

    func capturePhoto() {
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraService(self, didUpdateFrame: sampleBuffer)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            delegate?.cameraService(self, didFailWith: error)
            return
        }

        let previewImage: UIImage?
        if let previewCGImage = photo.previewCGImageRepresentation() {
            previewImage = UIImage(cgImage: previewCGImage)
        } else {
            previewImage = nil
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            delegate?.cameraService(self, didFailWith: CameraError.captureFailed)
            return
        }
        delegate?.cameraService(self, didCapturePhoto: image, previewImage: previewImage)
    }
}

extension CameraService {
    enum CameraError: LocalizedError {
        case setupFailed
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .setupFailed: return "Failed to set up camera"
            case .captureFailed: return "Failed to capture photo"
            }
        }
    }
}
