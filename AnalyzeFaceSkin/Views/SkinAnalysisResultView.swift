//
//  SkinAnalysisResultView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import SwiftUI
import SwiftData

struct SkinAnalysisResultView: View {
    let image: UIImage
    let result: SkinAnalysisResult
    let onDone: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        imageSection
                        
                        VStack(spacing: 16) {
                            skinTypeCard
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
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text("ANALYSIS REPORT")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.cyan)
                .bold()
                .tracking(3)
            Text("Your Skin Health")
                .font(.system(.title3, design: .rounded))
                .bold()
                .foregroundColor(.white)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var imageSection: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: Color.pink.opacity(0.3), radius: 10)
    }
    
    private var skinTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Skin Type Classifier")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.cyan)
                    .bold()
                Spacer()
                if let conf = result.skinTypeConfidence {
                    Text(String(format: "%.0f%% Match", conf * 100))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.pink)
                        .bold()
                }
            }
            
            let type = result.skinType ?? "Unknown"
            Text(type.capitalized)
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(.white)
            
            Text(descriptionForType(type))
                .font(.system(.footnote))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(nil)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    

    
    private var doneButton: some View {
        Button {
            saveToHistory()
            onDone()
        } label: {
            Text("Done")
                .font(.system(.headline, design: .rounded))
                .bold()
                .foregroundColor(.black)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.cyan, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color.pink.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }

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
    
    private func descriptionForType(_ type: String) -> String {
        switch type.lowercased() {
        case "oily":
            return "Excess sebum production makes skin appear shiny, especially in the T-zone. Pores may be enlarged and prone to blemishes."
        case "dry":
            return "Skin produces less sebum than normal, leading to dryness, tightness, or scaling. Needs intense hydration."
        case "combination":
            return "Mix of oily areas (usually T-zone) and dry or normal areas (cheeks). Target treatments for specific zones."
        case "normal":
            return "Balanced skin with good circulation, fine pores, and no extreme oil or dry patches. Maintain with hydration."
        default:
            return "Your skin is analyzed based on visual patterns detected by our AI classifier."
        }
    }
}

#Preview {
    SkinAnalysisResultView(
        image: UIImage(),
        result: SkinAnalysisResult(skinType: "combination", skinTypeConfidence: 0.85),
        onDone: {}
    )
}
