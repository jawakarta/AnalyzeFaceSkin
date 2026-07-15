//
//  HomeView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 13/07/26.
//

import SwiftUI

struct HomeView: View {
    @State private var showScanning = false
    @State private var showHistory = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1B2A4A"), Color(hex: "2E4057")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "face.smiling")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white)

                    Text("SKIN°82")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(spacing: 24) {
                    HomeButton(
                        icon: "camera.viewfinder",
                        title: "Scanning",
                        subtitle: "Scan your face now"
                    ) {
                        showScanning = true
                    }

                    HomeButton(
                        icon: "clock.arrow.circlepath",
                        title: "History",
                        subtitle: "View past results"
                    ) {
                        showHistory = true
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showScanning) {
            ContentView()
        }
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView()
        }
    }
}

struct HomeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(20)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
