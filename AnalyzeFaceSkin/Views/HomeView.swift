//
//  HomeView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 13/07/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("hasAcceptedAgreement") private var hasAcceptedAgreement = false
    @Query(sort: \SkinAnalysisHistory.createdAt, order: .reverse) private var histories: [SkinAnalysisHistory]
    
    @State private var showAgreement = false
    @State private var showScanning = false
    @State private var showHistory = false
    
    // Animation states for Scan Now button
    @State private var pulseScale1 = 1.0
    @State private var pulseOpacity1 = 0.5
    @State private var pulseScale2 = 1.0
    @State private var pulseOpacity2 = 0.3
    @State private var pulseScale3 = 1.0
    @State private var pulseOpacity3 = 0.1
    
    private var lastScanText: String {
        guard let lastScan = histories.first else { return "N/A" }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastScan.createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(lastScan.createdAt) {
            return "Yesterday"
        } else {
            let diff = calendar.dateComponents([.day], from: lastScan.createdAt, to: Date()).day ?? 0
            return "\(diff) days ago"
        }
    }
    
    private var avgScoreText: String {
        guard !histories.isEmpty else { return "0/100" }
        let total = histories.reduce(0.0) { $0 + $1.skinTypeConfidence }
        let avg = Int((total / Double(histories.count)) * 100)
        return "\(avg)/100"
    }

    var body: some View {
        ZStack {
            // Pastel warm peach to soft lavender gradient background
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
                Spacer()
                // Centered Animating Scan Button Area
                VStack(spacing: 32) {
                    ZStack {
                        // Outer Pulsing Ring 3
                        Circle()
                            .stroke(Color.white.opacity(1.2), lineWidth: 1.5)
                            .frame(width: 290, height: 290)
                            .scaleEffect(pulseScale3)
                            .opacity(pulseOpacity3)
                        
                        // Outer Pulsing Ring 2
                        Circle()
                            .stroke(Color.white.opacity(1.2), lineWidth: 1.5)
                            .frame(width: 250, height: 250)
                            .scaleEffect(pulseScale2)
                            .opacity(pulseOpacity2)
                        
                        // Outer Pulsing Ring 1
                        Circle()
                            .stroke(Color.white.opacity(1.2), lineWidth: 1.5)
                            .frame(width: 210, height: 210)
                            .scaleEffect(pulseScale1)
                            .opacity(pulseOpacity1)

                        // Main Central Button
                        Button {
                            showScanning = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "camera")
                                    .font(.system(size: 38, weight: .light))
                                    .foregroundColor(Color(hex: "5A4C47"))
                                
                                Text("SCAN NOW")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "5A4C47"))
                                    .tracking(1.5)
                            }
                            .frame(width: 176, height: 176)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
                        }
                    }
                    .frame(width: 300, height: 300)

                    // Description text below the button
                    Text("Scan your face to analyze your facial skin condition")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "6A5D58"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Stats Dashboard Row (3 Cards)
                HStack(spacing: 12) {
                    statCard(value: lastScanText, label: "Last Scan")
                    statCard(value: "\(histories.count)", label: "Total Scans")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Bottom History Card
                Button {
                    showHistory = true
                } label: {
                    HStack(spacing: 16) {
                        // Clock Icon Container
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "ECEAF8"))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "clock")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "5E52B7"))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scan History")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "3A2E2B"))
                            Text("View past analyses")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(Color(hex: "75635F"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "A39A96"))
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showScanning) {
            ContentView()
        }
        .fullScreenCover(isPresented: $showHistory) {
            HistoryView()
        }
        .fullScreenCover(isPresented: $showAgreement) {
            AgreementView()
        }
        .onAppear {
            if !hasAcceptedAgreement {
                showAgreement = true
            }
            
            // Start pulsing animations
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseScale1 = 1.35
                pulseOpacity1 = 0.0
            }
            
            withAnimation(Animation.easeOut(duration: 2.0).delay(0.65).repeatForever(autoreverses: false)) {
                pulseScale2 = 1.35
                pulseOpacity2 = 0.0
            }
        }
    }

    @ViewBuilder
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "3A2E2B"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "75635F"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SkinAnalysisHistory.self, inMemory: true)
}
