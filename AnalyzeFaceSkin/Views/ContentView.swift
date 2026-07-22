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
                        Color(hex: "FFE8F8"), // Soft pale rose
                        Color(hex: "F1F4FF"), // Soft lavender
                        Color(hex: "FFFFFF")  // Pure white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: 0) {
                        Spacer(minLength: 16)

                        FaceScanningView(
                            image: image,
                            landmarks: viewModel.capturedFaceLandmarks,
                            analysisResult: nil,
                            isAnalyzing: false
                        )

                        VStack(spacing: 8) {
                            Text("You’re ready to go!")
                                .font(.system(.title2))
                                .bold()
                                .foregroundColor(Color(hex: "3A2E2B"))

                            Text("We’ve captured your skin.\nLet’s analyze your results.")
                                .font(.system(.subheadline, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(hex: "75635F"))
                                .lineSpacing(3)
                        }
                        .padding(.top, 28)

                        Spacer(minLength: 20)

                        VStack(spacing: 16) {
                            // Analyze Now Button (Primary, placed on top)
                            Button {
                                viewModel.startScanning()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Analyze Now")
                                        .font(.system(.subheadline, design: .rounded))
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color(hex: "4d3865"))
                                .cornerRadius(24)
                                .shadow(color: Color(hex: "4d3865").opacity(0.35), radius: 8, x: 0, y: 4)
                            }

                            // Retake Button (Secondary, plain text below)
                            Button {
                                viewModel.reset()
                            } label: {
                                Text("Retake")
                                    .font(.system(.subheadline, design: .rounded))
                                    .bold()
                                    .foregroundColor(Color(hex: "b7aac7"))
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
                    
            case .scanning(let image):
                LinearGradient(
                    colors: [
                        Color(hex: "FFE8F8"), // Soft pale rose
                        Color(hex: "F1F4FF"), // Soft lavender
                        Color(hex: "FFFFFF")  // Pure white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay {
                    VStack(spacing: 24) {
                        Spacer(minLength: 24)

                        scanningStatusBadge

                        FaceScanningView(
                            image: image,
                            landmarks: viewModel.capturedFaceLandmarks,
                            analysisResult: nil,
                            isAnalyzing: true
                        )

                        Spacer(minLength: 24)
                    }
                }
                    
            case .result(let image, let result):
                LinearGradient(
                    colors: [
                        Color(hex: "FFE8F8"), // Soft pale rose
                        Color(hex: "F1F4FF"), // Soft lavender
                        Color(hex: "FFFFFF")  // Pure white
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
                    id:           UUID(),
                    image:        image,
                    result:       result,
                    clahePreview: viewModel.clahePreview
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
    private var scanningStatusBadge: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: "EE4B6A"))
                .frame(width: 10, height: 10)
                .shadow(color: Color(hex: "EE4B6A").opacity(0.8), radius: 4)

            Text("Scanning your skin...")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: "563D45"))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(hex: "EE4B6A").opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
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
