//
//  SkinAnalysisResultView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import SwiftUI
import SwiftData

// MARK: - Condition toggle state

private enum ConditionLayer: String, CaseIterable {
    case acne = "Acne"

    var color: Color { .red }

    var icon: String { "allergens" }
}

// MARK: - Main view

struct SkinAnalysisResultView: View {
    let image:            UIImage
    let result:           SkinAnalysisResult
    let grayscalePreview: UIImage?
    let clahePreview:     UIImage?
    let onDone:           () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var visibleLayers: Set<ConditionLayer> = Set(ConditionLayer.allCases)

    var body: some View {
        ZStack {
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

            VStack(spacing: 0) {
                headerView

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        annotatedImageSection
                            .padding(.horizontal, 20)

                        preprocessingSection
                            .padding(.horizontal, 20)

                        layerToggleRow
                            .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            skinTypeCard
                            conditionsSection
                        }
                        .padding(.horizontal, 20)

                        doneButton
                            .padding(.vertical, 20)
                    }
                    .padding(.top, 16)
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("ANALYSIS REPORT")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(hex: "75635F"))
                .bold()
                .tracking(3)
            Text("Your Skin Health")
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundColor(Color(hex: "3A2E2B"))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.15))
        .overlay(Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1),
                 alignment: .bottom)
    }

    // MARK: - Annotated image with bounding box overlay

    private var annotatedImageSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let imgSize = image.size
            let ratio   = imgSize.height / max(imgSize.width, 1)
            let h       = w * ratio

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )

                ForEach(ConditionLayer.allCases, id: \.self) { layer in
                    if visibleLayers.contains(layer) {
                        let boxes = boundingBoxes(for: layer)
                        ForEach(boxes.indices, id: \.self) { idx in
                            let box = boxes[idx]
                            BoundingBoxView(
                                box:        box,
                                color:      layer.color,
                                label:      layer.rawValue,
                                confidence: result.acneConfidence,
                                imageSize:  CGSize(width: w, height: h)
                            )
                        }
                    }
                }
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(image.size.width / max(image.size.height, 1), contentMode: .fit)
        .shadow(color: Color.cyan.opacity(0.15), radius: 12)
    }

    // MARK: - Preprocessing preview section

    @ViewBuilder
    private var preprocessingSection: some View {
        if grayscalePreview != nil || clahePreview != nil {
            VStack(alignment: .leading, spacing: 10) {
                Text("PREPROCESSING DEBUG")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(hex: "75635F"))
                    .bold()
                    .tracking(2)

                HStack(spacing: 10) {
                    if let gray = grayscalePreview {
                        previewCard(image: gray, label: "Grayscale",
                                    accent: Color(hex: "888888"))
                    }
                    if let clahe = clahePreview {
                        previewCard(image: clahe, label: "CLAHE (RGB)",
                                    accent: Color(hex: "5E52B7"))
                    }
                }
            }
        }
    }

    private func previewCard(image: UIImage, label: String, accent: Color) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.4), lineWidth: 1))

            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accent.opacity(0.1))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.8), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }

    // MARK: - Layer toggle pills

    private var layerToggleRow: some View {
        let hasAcne = !result.acneBoundingBoxes.isEmpty

        return HStack(spacing: 10) {
            if hasAcne {
                let active = visibleLayers.contains(.acne)
                Button {
                    if active { visibleLayers.remove(.acne) }
                    else      { visibleLayers.insert(.acne) }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: ConditionLayer.acne.icon)
                            .font(.system(size: 11))
                        Text(ConditionLayer.acne.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(active ? .black : ConditionLayer.acne.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(active ? ConditionLayer.acne.color : ConditionLayer.acne.color.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ConditionLayer.acne.color.opacity(active ? 0 : 0.4), lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Skin Type card

    private var skinTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Skin Type", systemImage: "drop.fill")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(Color(hex: "5E52B7"))
                    .bold()
                Spacer()
                if let conf = result.skinTypeConfidence {
                    Text(String(format: "%.0f%% Match", conf * 100))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(hex: "E95B82"))
                        .bold()
                }
            }

            let type = result.skinType ?? "Unknown"
            Text(type.capitalized)
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(Color(hex: "3A2E2B"))

            Text(descriptionForType(type))
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(Color(hex: "75635F"))
                .lineLimit(nil)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.8), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }

    // MARK: - Conditions section

    private var conditionsSection: some View {
        VStack(spacing: 12) {
            Text("CONDITION SCAN")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(hex: "75635F"))
                .bold()
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            let hasAcne = !result.acneBoundingBoxes.isEmpty

            if hasAcne {
                conditionRow(
                    layer: .acne,
                    count: result.acneBoundingBoxes.count,
                    level: result.acneLevel,
                    description: "Inflammatory lesions or comedones detected on skin surface."
                )
            } else {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("All Clear!")
                            .font(.system(.subheadline, design: .rounded))
                            .bold()
                            .foregroundColor(Color(hex: "3A2E2B"))

                        Text("No significant acne detected on your skin.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color(hex: "75635F"))
                            .lineLimit(nil)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
            }
        }
    }

    @ViewBuilder
    private func conditionRow(
        layer: ConditionLayer,
        count: Int,
        level: String?,
//        confidence: Double?,
        description: String
    ) -> some View {
        let levelText = level ?? "Unknown"

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(layer.color)
                    .frame(width: 4, height: 24)

                Image(systemName: layer.icon)
                    .foregroundColor(layer.color)
                    .frame(width: 18)

                Text(layer.rawValue)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(Color(hex: "3A2E2B"))
                    .bold()

                if count > 0 {
                    Text("\(count) region\(count > 1 ? "s" : "")")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(layer.color.opacity(0.9))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(layer.color.opacity(0.12))
                        .cornerRadius(8)
                }

                Spacer()

//                if let conf = confidence {
//                    Text(String(format: "%.0f%%", conf * 100))
//                        .font(.system(.caption, design: .monospaced))
//                        .foregroundColor(Color(hex: "5E52B7"))
//                        .bold()
//                }

                Text(levelText.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(badgeColor(for: levelText))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor(for: levelText).opacity(0.15))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(badgeColor(for: levelText).opacity(0.4), lineWidth: 1)
                    )
            }

            Text(description)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(hex: "75635F"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.8), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }

    // MARK: - Done button

    private var doneButton: some View {
        Button {
            saveToHistory()
            onDone()
        } label: {
            Text("Back to home")
                .font(.system(.headline, design: .rounded))
                .bold()
                .foregroundColor(.white)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(LinearGradient(
                    colors: [Color(hex: "5E52B7"), Color(hex: "E95B82")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .cornerRadius(25)
                .shadow(color: Color(hex: "E95B82").opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Save to history

    private func saveToHistory() {
        guard let skinType = result.skinType else { return }
        let imageData = image.jpegData(compressionQuality: 0.6)
        let history = SkinAnalysisHistory(
            skinType: skinType,
            skinTypeConfidence: result.skinTypeConfidence ?? 0,
            imageData: imageData
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func boundingBoxes(for layer: ConditionLayer) -> [SkinBoundingBox] {
        switch layer {
        case .acne: return result.acneBoundingBoxes
        }
    }

    private func badgeColor(for level: String) -> Color {
        switch level.lowercased() {
        case "severe", "high":   return .red
        case "moderate": return .orange
        default:         return .green
        }
    }

    private func descriptionForType(_ type: String) -> String {
        switch type.lowercased() {
        case "oily":    return "Excess sebum makes skin shiny, especially in T-zone. Pores may be enlarged."
        case "dry":     return "Less sebum than normal — skin may feel tight or flaky. Needs intense hydration."
        case "normal":  return "Balanced skin with fine pores and no extreme oil or dryness."
        default:        return "Skin analyzed from visual patterns detected by our AI."
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
            // ── 1. Instance Segmentation Mask Polygon ────────────────────────
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
                // Fallback to bounding box fill
                color.opacity(0.15)
                    .frame(width: pixelRect.width, height: pixelRect.height)
                    .position(x: pixelRect.midX, y: pixelRect.midY)
            }

            // ── 2. Bounding Box Border ───────────────────────────────────────
            RoundedRectangle(cornerRadius: 6)
                .stroke(color, lineWidth: 1.5)
                .frame(width: pixelRect.width, height: pixelRect.height)
                .position(x: pixelRect.midX, y: pixelRect.midY)

            // ── 3. Confidence Score Pill (Premium styling matching YOLO) ─────
            let scoreVal = confidence ?? 0.86
            let labelText = String(format: "%.2f", scoreVal)
            
            Text(labelText)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                .position(x: pixelRect.midX, y: pixelRect.minY - 10)
        }
    }
}

// MARK: - Preview

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
        grayscalePreview: nil,
        clahePreview:     nil,
        onDone:           {}
    )
}
