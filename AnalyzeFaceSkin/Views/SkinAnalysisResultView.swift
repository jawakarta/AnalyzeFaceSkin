//
//  SkinAnalysisResultView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import SwiftUI
import SwiftData


private enum ConditionLayer: String, CaseIterable {
    case acne = "Acne"

    var color: Color { .red }

    var icon: String { "allergens" }
}


struct SkinAnalysisResultView: View {
    let image:         UIImage
    let result:        SkinAnalysisResult
    let clahePreview:  UIImage?
    var isFromHistory: Bool = false
    let onDone:        () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToAcneDetail = false
    @State private var navigateToSkinTypeDetail = false
    @State private var hasSavedHistory = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FDF7FB"), // Soft pale rose
                    Color(hex: "F7F6FD"), // Soft lavender
                    Color(hex: "FFFFFF")  // Pure white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBarView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Skintuation")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Here's what we found from your scan.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        
                        annotatedImageSection
                            .padding(.horizontal, 20)

                        skinSummaryCard
                            .padding(.horizontal, 20)

                        findingsSection
                            .padding(.horizontal, 20)
                        
                        if !isFromHistory {
                            backToHomeButton
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, 12)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToAcneDetail) {
            AcneDetailView(spotCount: result.acneBoundingBoxes.count)
        }
        .navigationDestination(isPresented: $navigateToSkinTypeDetail) {
            SkinTypeDetailView(skinType: result.skinType ?? "Normal")
        }
        .navigationBarHidden(true)
        .onAppear {
            saveToHistory()
        }
    }


    private var topBarView: some View {
        HStack {
            Button(action: {
                if isFromHistory {
                    dismiss()
                } else {
                    saveToHistory()
                    onDone()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }


    private var spotCountText: String {
        let count = result.acneBoundingBoxes.count
        return "\(count) \(count == 1 ? "spot" : "spots")"
    }

    private var annotatedImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(24)
                .overlay(
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            let boxes = result.acneBoundingBoxes
                            ForEach(boxes.indices, id: \.self) { idx in
                                BoundingBoxView(
                                    box: boxes[idx],
                                    color: .red,
                                    label: "Acne",
                                    confidence: result.acneConfidence,
                                    imageSize: geo.size
                                )
                            }
                        }
                    }
                )
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                Text("\(spotCountText) detected")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(20)
            .padding([.leading, .bottom], 16)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }


    private var skinSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("Your Skin Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            let type = result.skinType ?? "Unknown"
            let count = result.acneBoundingBoxes.count
            let acneText: String = {
                if count == 0 {
                    return "without significant acne spots"
                } else if count == 1 {
                    return "with 1 visible acne spot"
                } else {
                    return "with \(count) visible acne spots"
                }
            }()
            
            Text("Your scan shows an \(type.lowercased()) skin type \(acneText). With the right care, your skin can look clearer and healthier.")
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.1)).frame(width: 36, height: 36)
                        Image(systemName: "drop.fill").foregroundColor(.blue).font(.system(size: 14))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skin Type").font(.system(size: 10)).foregroundColor(.gray)
                        Text(type.capitalized).font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                    }
                }
                
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.red.opacity(0.1)).frame(width: 36, height: 36)
                        Circle().fill(Color.red).frame(width: 12, height: 12)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Acne").font(.system(size: 10)).foregroundColor(.gray)
                        Text(spotCountText).font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 8, y: 4)
    }


    private var findingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Findings")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            let type = result.skinType ?? "Unknown"
            Button(action: {
                navigateToSkinTypeDetail = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.08)).frame(width: 44, height: 44)
                        Image(systemName: "drop.fill").foregroundColor(.blue).font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skin Type").font(.caption).foregroundColor(.gray)
                        Text(type.capitalized).font(.body).fontWeight(.bold).foregroundColor(.black)
                        Text(descriptionForType(type)).font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            let count = result.acneBoundingBoxes.count
            let acneDescText: String = {
                if count == 0 {
                    return "No visible acne spots detected on your skin."
                } else if count == 1 {
                    return "1 visible acne spot detected on your skin."
                } else {
                    return "\(count) visible acne spots detected on your skin."
                }
            }()
            
            let acneCard = HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.red.opacity(0.08)).frame(width: 44, height: 44)
                    Circle().fill(Color.red).frame(width: 14, height: 14)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Acne").font(.caption).foregroundColor(.gray)
                    Text(spotCountText).font(.body).fontWeight(.bold).foregroundColor(.black)
                    Text(acneDescText).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                if count > 0 {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            
            if count > 0 {
                Button(action: {
                    navigateToAcneDetail = true
                }) {
                    acneCard
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                acneCard
            }
            
            HStack(spacing: 12) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                Text("Tip: Tap any finding to learn more and get personalized skin tips.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }


    private var backToHomeButton: some View {
        Button(action: {
            saveToHistory()
            onDone()
        }) {
            Text("Back to Home")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.11, green: 0.11, blue: 0.14))
                .cornerRadius(28)
        }
    }


    private func saveToHistory() {
        guard !isFromHistory, !hasSavedHistory, let skinType = result.skinType else { return }
        hasSavedHistory = true
        let imageData = image.jpegData(compressionQuality: 0.6)
        let history = SkinAnalysisHistory(
            skinType: skinType,
            skinTypeConfidence: result.skinTypeConfidence ?? 0,
            acneSpotCount: result.acneBoundingBoxes.count,
            acneBoundingBoxes: result.acneBoundingBoxes,
            imageData: imageData
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    private func descriptionForType(_ type: String) -> String {
        switch type.lowercased() {
        case "oily":    return "Produces more oil than average."
        case "dry":     return "Produces less oil than average."
        case "normal":  return "Balanced hydration level."
        default:        return "Analyzed vision patterns."
        }
    }
}

private struct BoundingBoxView: View {
    let box:        SkinBoundingBox
    let color:      Color
    let label:      String
    let confidence: Double?
    let imageSize:  CGSize

    private var pixelRect: CGRect {
        let rect = box.cgRect
        return CGRect(
            x:      rect.origin.x    * imageSize.width,
            y:      rect.origin.y    * imageSize.height,
            width:  rect.size.width  * imageSize.width,
            height: rect.size.height * imageSize.height
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let pts = box.polygonPoints, !pts.isEmpty {
                Path { path in
                    guard let first = pts.first else { return }
                    path.move(to: CGPoint(x: first.x * imageSize.width, y: first.y * imageSize.height))
                    for pt in pts.dropFirst() {
                        path.addLine(to: CGPoint(x: pt.x * imageSize.width, y: pt.y * imageSize.height))
                    }
                    path.closeSubpath()
                }
                .fill(color.opacity(0.35))
            } else {
                color.opacity(0.15)
                    .frame(width: pixelRect.width, height: pixelRect.height)
                    .position(x: pixelRect.midX, y: pixelRect.midY)
            }

            RoundedRectangle(cornerRadius: 6)
                .stroke(color, lineWidth: 1.5)
                .frame(width: pixelRect.width, height: pixelRect.height)
                .position(x: pixelRect.midX, y: pixelRect.midY)

            let labelText: String = {
                if let conf = confidence {
                    return String(format: "%@ %.0f%%", label, conf * 100)
                } else {
                    return label
                }
            }()
            
            Text(labelText)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                .position(x: pixelRect.midX, y: max(10, pixelRect.minY - 10))
        }
    }
}


#Preview {
    SkinAnalysisResultView(
        image:            UIImage(),
        result:           SkinAnalysisResult(
            skinType: "oily",
            skinTypeConfidence: 0.85,
            acneLevel: "moderate",
            acneConfidence: 0.72,
            acneBoundingBoxes: [
                SkinBoundingBox(x: 0.15, y: 0.25, width: 0.18, height: 0.14),
                SkinBoundingBox(x: 0.60, y: 0.30, width: 0.12, height: 0.10)
            ]
        ),
        clahePreview:     nil,
        onDone:           {}
    )
}
