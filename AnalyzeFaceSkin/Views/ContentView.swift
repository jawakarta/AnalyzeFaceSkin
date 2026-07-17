//
//  ContentView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
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
                LinearGradient(
                    colors: [
                        Color(hex: "F3B8A5"), // Soft Warm Peach
                        Color(hex: "EBD4E2"), // Pastel Creamy Pink
                        Color(hex: "D7D3EA")  // Gentle Lavender
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay {
                    VStack {
                        Spacer()

                        FaceScanningView(
                            image: image,
                            landmarks: viewModel.capturedFaceLandmarks,
                            analysisResult: nil,
                            isAnalyzing: true
                        )

                        Button("Cancel") {
                            viewModel.reset()
                        }
                        .foregroundColor(Color(hex: "3A2E2B"))
                        .font(.system(.subheadline, design: .rounded))
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
                        .padding(.bottom, 50)

                        Spacer()
                    }
                }
                    
            case .result(let image, let result):
                SkinAnalysisResultView(image: image, result: result) {
                    viewModel.reset()
                    dismiss()
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
        .alert("Face Not Detected", isPresented: $viewModel.showNoFaceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The photo you selected or took didn't clearly detect the face. Please try again with better lighting and angle.")
        }
        .alert("Analysis Failed", isPresented: $viewModel.showAnalysisErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.analysisError ?? "Unknown error occurred.")
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
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.leading, 20)
                .padding(.top, 16)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
            .overlay(alignment: .center) {
                FaceOverlayView(
                    faceState: viewModel.faceState,
                    ovalColor: viewModel.ovalColor,
                    progress: viewModel.captureProgress
                )
            }
            .overlay(alignment: .bottom) {
                GuideTextView(text: viewModel.guideText)
                    .padding(.bottom, 80)
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
