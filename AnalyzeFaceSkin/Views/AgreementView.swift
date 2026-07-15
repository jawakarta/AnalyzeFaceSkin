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
                colors: [Color(hex: "1B2A4A"), Color(hex: "2E4057")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header Icon & Title
                VStack(spacing: 12) {
                    Image(systemName: "shield.and.person.badge.shield.checkmark.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.cyan.opacity(0.3), radius: 10)
                        .padding(.top, 40)

                    Text("PRIVACY AGREEMENT")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.cyan)
                        .bold()
                        .tracking(3)

                    Text("Skin Scan Consent")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.white)
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
                            description: "Images are processed locally using advanced AI models to analyze skin type, acne areas, and wrinkle patterns."
                        )

                        agreementItem(
                            icon: "lock.shield.fill",
                            title: "Privacy Guaranteed",
                            description: "Your raw photos and analysis records are saved only on your local device. We never upload your images to any cloud server or share them with third parties."
                        )
                    }
                    .padding(20)
                }
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                // Consent Checkbox
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isChecked.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isChecked ? Color.cyan : Color.white.opacity(0.4), lineWidth: 2)
                                .frame(width: 24, height: 24)

                            if isChecked {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.cyan)
                                    .frame(width: 24, height: 24)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }

                        Text("I agree to allow the app to capture my face image for local machine learning analysis.")
                            .font(.system(.footnote))
                            .foregroundColor(.white.opacity(0.8))
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
                        .foregroundColor(isChecked ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isChecked ?
                            LinearGradient(
                                colors: [Color.cyan, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.08)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: isChecked ? Color.pink.opacity(0.2) : Color.clear, radius: 10, x: 0, y: 5)
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
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .frame(width: 28, height: 28)
                .background(Color.cyan.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(.caption))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(nil)
            }
        }
    }
}

#Preview {
    AgreementView()
}
