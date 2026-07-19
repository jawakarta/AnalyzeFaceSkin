//
//  ContentView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @Binding var navPath: [AppScreen]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CameraViewModel()
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Group {
            switch viewModel.captureState {
            case .idle, .detecting, .aligning, .ready, .capturing:
                ZStack {
                    cameraLayer
                    flashOverlay
                }
                .onAppear { viewModel.setup() }
                
            case .captured(let image):
                LinearGradient(
                    colors: [
                        Color(hex: "F3B8A5"),
                        Color(hex: "EBD4E2"),
                        Color(hex: "D7D3EA")
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
                            isAnalyzing: false
                        )

                        HStack(spacing: 16) {
                            Button("Retake") {
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

                            Button {
                                viewModel.startScanning()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Analyze")
                                        .font(.system(.subheadline, design: .rounded))
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "5E52B7"), Color(hex: "E95B82")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: Color(hex: "5E52B7").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.bottom, 50)

                        Spacer()
                    }
                }
                    
            case .scanning(let image):
                LinearGradient(
                    colors: [
                        Color(hex: "F3B8A5"),
                        Color(hex: "EBD4E2"),
                        Color(hex: "D7D3EA")
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
                LinearGradient(
                    colors: [
                        Color(hex: "F3B8A5"),
                        Color(hex: "EBD4E2"),
                        Color(hex: "D7D3EA")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .onChange(of: viewModel.captureState) { _, newState in
            if case .result(let image, let result) = newState {
                navPath.append(.result(
                    image:            image,
                    result:           result,
                    grayscalePreview: viewModel.grayscalePreview,
                    clahePreview:     viewModel.clahePreview
                ))
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
