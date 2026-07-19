//
//  AgreementView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 15/07/26.
//

import SwiftUI

struct AgreementView: View {
    @AppStorage("hasAcceptedAgreement") private var hasAcceptedAgreement = false
    @Environment(\.dismiss) private var dismiss
    @State private var isChecked = false

    var body: some View {
        ZStack {
            // Premium background gradient matching home
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

            VStack(spacing: 24) {
                // Header Icon & Title
                VStack(spacing: 12) {
                    Image(systemName: "shield.and.person.badge.shield.checkmark.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "5E52B7"), Color(hex: "E95B82")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "5E52B7").opacity(0.2), radius: 10)
                        .padding(.top, 40)

                    Text("PRIVACY AGREEMENT")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(hex: "75635F"))
                        .bold()
                        .tracking(3)

                    Text("Skin Scan Consent")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(Color(hex: "3A2E2B"))
                }

                // Scrollable Info Box
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
                        agreementItem(
                            icon: "camera.fill",
                            title: "Camera Capture",
                            description: "Our application requires camera access to capture a clear image of your face for accurate skin analysis."
                        )

                        agreementItem(
                            icon: "cpu",
                            title: "On-Device Machine Learning",
                            description: "Images are processed locally using advanced AI models to analyze skin type and acne conditions."
                        )

                        agreementItem(
                            icon: "lock.shield.fill",
                            title: "Privacy Guaranteed",
                            description: "Your raw photos and analysis records are saved only on your local device. We never upload your images to any cloud server or share them with third parties."
                        )
                    }
                    .padding(20)
                }
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)

                // Consent Checkbox
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isChecked.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isChecked ? Color(hex: "5E52B7") : Color(hex: "3A2E2B").opacity(0.4), lineWidth: 2)
                                .frame(width: 24, height: 24)

                            if isChecked {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "5E52B7"))
                                    .frame(width: 24, height: 24)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("I agree to allow the app to capture my face image for local machine learning analysis.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(Color(hex: "3A2E2B"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical, 8)

                // Confirm Button
                Button {
                    if isChecked {
                        hasAcceptedAgreement = true
                        dismiss()
                    }
                } label: {
                    Text("Confirm & Continue")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundColor(isChecked ? .white : Color(hex: "75635F").opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isChecked ?
                            LinearGradient(
                                colors: [Color(hex: "5E52B7"), Color(hex: "E95B82")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: isChecked ? Color(hex: "E95B82").opacity(0.2) : Color.clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isChecked)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func agreementItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "5E52B7"))
                .frame(width: 28, height: 28)
                .background(Color(hex: "5E52B7").opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(Color(hex: "3A2E2B"))

                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color(hex: "75635F"))
                    .lineLimit(nil)
            }
        }
    }
}

#Preview {
    AgreementView()
}
