//
//  AcneDetailView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 20/07/26.
//

import SwiftUI

struct AcneDetailView: View {
    var spotCount: Int = 0
    @Environment(\.dismiss) private var dismiss
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderSection(spotCount: spotCount)
                    
                    DetectionAlertBox(spotCount: spotCount)
                    
                    CausesSection()
                    
                    Divider()
                    
                    SkinCareSection()
                    
                    Divider()
                    
                    PreventionSection()
                    
                    TakeawayBox()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}


struct HeaderSection: View {
    let spotCount: Int
    
    var body: some View {
        HStack(alignment: .center) {
            Circle()
                .fill(Color.red.opacity(0.6))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().fill(Color.red).frame(width: 12, height: 12)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Acne")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("\(spotCount) spot\(spotCount == 1 ? "" : "s") detected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)
            

            
        }
        .padding(.vertical, 8)
    }
}

struct DetectionAlertBox: View {
    let spotCount: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "viewfinder")
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.35))
                .overlay(
                    Circle()
                        .fill(Color(red: 0.85, green: 0.35, blue: 0.35))
                        .frame(width: 6, height: 6)
                )
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(spotCount > 0
                    ? "We detected \(spotCount) visible acne spot\(spotCount == 1 ? "" : "s")."
                    : "No visible acne spots were detected.")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("No worries, everyone gets acne sometimes. Understanding the cause is the first step to healthier skin.")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.94, blue: 0.94))
        .cornerRadius(12)
    }
}

struct CausesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("What causes acne?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            } icon: {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.4))
            }
            
            VStack(alignment: .leading, spacing: 14) {
                CauseRow(icon: "drop.fill", text: "Excess oil production", color: Color(red: 0.4, green: 0.2, blue: 0.3))
                CauseRow(icon: "sparkles", text: "Dead skin cells buildup", color: Color(red: 0.7, green: 0.4, blue: 0.4))
                CauseRow(icon: "gearshape.fill", text: "Bacteria on the skin", color: Color(red: 0.7, green: 0.3, blue: 0.3))
                CauseRow(icon: "waveform", text: "Hormonal changes", color: Color(red: 0.9, green: 0.5, blue: 0.5))
                CauseRow(icon: "moon.stars.fill", text: "Stress and lack of sleep", color: Color(red: 0.4, green: 0.3, blue: 0.6))
            }
            .padding(.top, 4)
        }
    }
}

struct CauseRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

struct SkinCareSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("How to care for your skin")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            } icon: {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
            }
            
            
            VStack(alignment: .leading, spacing: 16) {
                ChecklistRow(text: "Cleanse your face twice a day with a gentle cleanser.", color: .green)
                ChecklistRow(text: "Avoid touching or picking pimples.", color: .green)
                ChecklistRow(text: "Use lightweight, non-comedogenic moisturizer.", color: .green)
                ChecklistRow(text: "Wear sunscreen every day.", color: .green)
            }
        }
    }
}

struct PreventionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("How to prevent more breakouts")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            } icon: {
                Image(systemName: "shield")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ChecklistRow(iconName: "square.on.square", text: "Change pillowcases and towels regularly.", color: .purple)
                ChecklistRow(iconName: "face.dashed", text: "Remove makeup before bed.", color: .purple)
                ChecklistRow(iconName: "drop", text: "Keep your face clean, especially after sweating.", color: .purple)
                ChecklistRow(iconName: "takeoutbag.and.cup.and.straw", text: "Maintain a balanced diet and drink enough water.", color: .purple)
            }
            .padding(.top, 4)
        }
    }
}

struct ChecklistRow: View {
    var iconName: String = "checkmark.circle"
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TakeawayBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "star")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("Today's Takeaway")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.1))
            }
            
            Text("Consistency is key! A gentle routine and good habits can help reduce existing breakouts and prevent new ones.")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.1).opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.98, blue: 0.92))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        AcneDetailView()
    }
}
