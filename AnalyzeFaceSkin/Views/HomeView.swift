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
    @State private var showHistory = false
    
    // Push navigation path
    @State private var navPath = [AppScreen]()
    
    // Animation states for Scan button & rings
    @State private var pulseScale1: CGFloat = 1.0
    @State private var pulseScale2: CGFloat = 1.0
    @State private var pulseScale3: CGFloat = 1.0
    @State private var pulseOpacity1: Double = 1.5
    @State private var pulseOpacity2: Double = 1.3
    @State private var pulseOpacity3: Double = 1.1
    
    private var lastScanText: String {
        guard let lastScan = histories.first else { return "No scans yet" }
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

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // Subtle warm pink/lavender to white background gradient
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
                    // ── Header Section ──────────────────────────────────────────
                    VStack(spacing: 8) {
                        Text("Good morning,")
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .foregroundColor(Color(hex: "757482"))
                        
                        Text("Let's take care of your skin.")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(Color(hex: "1C1B24"))
                        
                        Text("Scan your skin to get personalized\ninsights and recommendations.")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(Color(hex: "8E8D9E"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                    Spacer()

                    // ── Central Pulsing Scan Button with concentric dashed rings ──
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

                        // Main central scan button
                        Button {
                            navPath.append(.camera)
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "camera")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "E06B92"), Color(hex: "5E52B7")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Scan Your Skin")
                                    .font(.system(size: 15, weight: .bold, design: .default))
                                    .foregroundColor(Color(hex: "1C1B24"))
                                
                                Text("Tap to start")
                                    .font(.system(size: 12, weight: .medium, design: .default))
                                    .foregroundColor(Color(hex: "8E8D9E"))
                            }
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color(hex: "5E52B7").opacity(0.08), radius: 20, x: 0, y: 10)
                        }
                    }
                    .frame(width: 300, height: 300)

                    Spacer()

                    // ── Dashboard Row (Last Scan & Total Scan Cards) ──────────────
                    HStack(spacing: 16) {
                        // Card 1: Last Scan
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "F0EEFC"))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "5E52B7"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastScanText)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "1C1B24"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                
                                Text("Last Scan")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "8E8D9E"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "F2F0F7"), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            // Wave decoration at bottom right
                            Circle()
                                .fill(Color(hex: "5E52B7").opacity(0.04))
                                .frame(width: 70, height: 70)
                                .blur(radius: 12)
                                .offset(x: 35, y: 35),
                            alignment: .bottomTrailing
                        )
                        .shadow(color: Color.black.opacity(0.015), radius: 10, x: 0, y: 5)

                        // Card 2: Total Scan
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "FDF2EC"))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "E58A59"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(histories.count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "1C1B24"))
                                
                                Text("Total Scan")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "8E8D9E"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "F2F0F7"), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            // Wave decoration at bottom right
                            Circle()
                                .fill(Color(hex: "E58A59").opacity(0.04))
                                .frame(width: 70, height: 70)
                                .blur(radius: 12)
                                .offset(x: 35, y: 35),
                            alignment: .bottomTrailing
                        )
                        .shadow(color: Color.black.opacity(0.015), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                    // ── Bottom History Card ─────────────────────────────────────
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "EAE8FA"))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "5E52B7"))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("History")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: "1C1B24"))
                                Text("View past analyses")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "8E8D9E"))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "A39A96"))
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "F2F0F7"), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.015), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(for: AppScreen.self) { screen in
                switch screen {
                case .camera:
                    ContentView(navPath: $navPath)
                        .navigationBarBackButtonHidden(true)
                case .result(let image, let result, let grayscale, let clahe):
                    SkinAnalysisResultView(
                        image:            image,
                        result:           result,
                        grayscalePreview: grayscale,
                        clahePreview:     clahe
                    ) {
                        navPath.removeAll()
                    }
                    .navigationBarBackButtonHidden(true)
                }
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
                
                // Radiating pulse waves (from 1.0 to 1.35 scale, opacity fades to 0.0)
                withAnimation(Animation.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                    pulseScale1 = 1.35
                    pulseOpacity1 = 0.0
                }
                
                withAnimation(Animation.easeOut(duration: 2.2).delay(0.7).repeatForever(autoreverses: false)) {
                    pulseScale2 = 1.35
                    pulseOpacity2 = 0.0
                }
                
                withAnimation(Animation.easeOut(duration: 2.2).delay(1.4).repeatForever(autoreverses: false)) {
                    pulseScale3 = 1.35
                    pulseOpacity3 = 0.0
                }
            }
        }
    }
}

// Push navigation destinations
enum AppScreen: Hashable {
    case camera
    case result(image: UIImage,
                result: SkinAnalysisResult,
                grayscalePreview: UIImage?,
                clahePreview: UIImage?)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .camera:
            hasher.combine(0)
        case .result(let image, let result, _, _):
            hasher.combine(1)
            hasher.combine(image.pngData()?.count ?? 0)
            hasher.combine(result)
        }
    }
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.camera, .camera):
            return true
        case (.result(let img1, let res1, _, _), .result(let img2, let res2, _, _)):
            return img1 == img2 && res1 == res2
        default:
            return false
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: SkinAnalysisHistory.self, inMemory: true)
}
