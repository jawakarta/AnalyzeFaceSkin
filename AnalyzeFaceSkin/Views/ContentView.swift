//
//  ContentView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Group {
            switch viewModel.captureState {
            case .idle, .detecting, .aligning, .ready, .capturing, .captured:
                ZStack {
                    cameraLayer
                    flashOverlay
                    
                    if case .captured(let image) = viewModel.captureState {
                        Color.black.opacity(0.5).ignoresSafeArea()
                            .overlay {
                                VStack {
                                    Spacer()

                                    // Static preview of the captured face
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(16)
                                        .padding(40)

                                    HStack(spacing: 40) {
                                        Button("Retake") {
                                            viewModel.reset()
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.gray)
                                        .clipShape(Circle())

                                        Button("Scan") {
                                            viewModel.startScanning()
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.blue)
                                        .clipShape(Circle())
                                    }

                                    Spacer()
                                }
                            }
                    }
                }
                .onAppear { viewModel.setup() }
                
            case .scanning(let image):
                Color.black.ignoresSafeArea()
                    .overlay {
                        VStack {
                            Spacer()

                            // Full screen scanning animation page (camera stopped!)
                            FaceScanningView(image: image, landmarks: viewModel.capturedFaceLandmarks)

                            HStack(spacing: 40) {
                                Button("Cancel") {
                                    viewModel.reset()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(.gray)
                                .clipShape(Circle())

                                Button("Save") {
                                    viewModel.savePhoto()
                                    viewModel.reset()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(.blue)
                                .clipShape(Circle())
                            }
                            .padding(.bottom, 50)

                            Spacer()
                        }
                    }
            }
        }
        .onChange(of: selectedPhoto) { _, item in loadPhoto(from: item) }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto)
        .alert("Camera Required", isPresented: $viewModel.permissionDenied) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant camera access in Settings.")
        }
        .alert("Wajah Tidak Terdeteksi", isPresented: $viewModel.showNoFaceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Foto yang Anda pilih atau ambil tidak mendeteksi wajah dengan jelas. Silakan coba lagi dengan pencahayaan dan sudut yang lebih baik.")
        }
    }

    @ViewBuilder
    private var flashOverlay: some View {
        if viewModel.isFlashOn && !viewModel.cameraService.isTorchAvailable {
            Color.white
                .ignoresSafeArea()
                .opacity(1.0)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var cameraLayer: some View {
        CameraPreviewView(cameraService: viewModel.cameraService)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                GuideTextView(text: viewModel.guideText)
                    .padding(.top, 60)
            }
            .overlay(alignment: .center) {
                FaceOverlayView(
                    faceState: viewModel.faceState,
                    ovalColor: viewModel.ovalColor,
                    progress: viewModel.captureProgress
                )
            }
            .overlay(alignment: .bottom) {
                CaptureControlsView(
                    onCapture: { viewModel.capturePhoto() },
                    onGallery: { showPhotoPicker = true },
                    onSettings: {},
                    onFlash: { viewModel.toggleFlash() },
                    isFlashOn: viewModel.isFlashOn,
                    showFlash: viewModel.lightingCondition == .lowLight,
                    isCaptureDisabled: !viewModel.faceState.isDetected
                )
                .padding(.bottom, 40)
            }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.importPhoto(from: image)
                }
            }
        }
    }
}
