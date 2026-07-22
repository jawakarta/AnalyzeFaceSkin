//
//  SkinTypeDetailView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 21/07/26.
//

import SwiftUI

struct SkinTypeInfo {
    let title: String
    let whatIsIt: String
    let characteristics: [String]
    let dailyCareTips: [String]
    let habitsToAvoid: [String]
    let takeaway: String
    
    static func getInfo(for skinType: String) -> SkinTypeInfo {
        let normalized = skinType.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalized.contains("oily") {
            return SkinTypeInfo(
                title: "Oily Skin",
                whatIsIt: "Your skin produces more sebum (natural oil) than average. Sebum helps protect your skin and maintain its moisture, but excess oil can make your skin appear shiny and increase the chance of clogged pores and acne.",
                characteristics: [
                    "Shiny appearance, especially on the forehead, nose, and chin (T-zone)",
                    "Larger-looking pores",
                    "Makeup tends to wear off more quickly",
                    "More likely to experience clogged pores and acne"
                ],
                dailyCareTips: [
                    "Wash your face twice daily with a gentle cleanser.",
                    "Use an oil-free or non-comedogenic moisturizer.",
                    "Wear sunscreen every day.",
                    "Avoid harsh scrubbing, which may irritate the skin."
                ],
                habitsToAvoid: [
                    "Washing your face too frequently.",
                    "Picking or squeezing pimples.",
                    "Using products that clog pores."
                ],
                takeaway: "Oily skin is common. A gentle and consistent skincare routine helps manage excess oil while maintaining a healthy skin barrier."
            )
        } else if normalized.contains("dry") {
            return SkinTypeInfo(
                title: "Dry Skin",
                whatIsIt: "Dry skin produces less sebum than needed to maintain the skin's natural barrier. As a result, moisture escapes more easily, making the skin feel tight, rough, or flaky.",
                characteristics: [
                    "Tight feeling after cleansing",
                    "Rough or flaky patches",
                    "Dull appearance",
                    "Skin may become irritated more easily"
                ],
                dailyCareTips: [
                    "Use a gentle, fragrance-free cleanser.",
                    "Apply moisturizer immediately after washing your face.",
                    "Choose products containing ingredients such as ceramides or glycerin.",
                    "Wear sunscreen every day."
                ],
                habitsToAvoid: [
                    "Hot showers or hot water.",
                    "Over-exfoliating.",
                    "Skipping moisturizer."
                ],
                takeaway: "Keeping your skin hydrated helps support its natural barrier and reduces dryness."
            )
        } else {
            // Default to Normal Skin
            return SkinTypeInfo(
                title: "Normal Skin",
                whatIsIt: "Normal skin has a balanced level of oil and moisture. It is generally neither too oily nor too dry and usually has a healthy skin barrier.",
                characteristics: [
                    "Smooth texture",
                    "Comfortable throughout the day",
                    "Few dry or oily areas",
                    "Small to medium-sized pores"
                ],
                dailyCareTips: [
                    "Cleanse gently twice daily.",
                    "Moisturize regularly.",
                    "Wear sunscreen every day.",
                    "Maintain a consistent skincare routine."
                ],
                habitsToAvoid: [
                    "Excessive exfoliation.",
                    "Sleeping with makeup on.",
                    "Forgetting sunscreen."
                ],
                takeaway: "Balanced skin still benefits from daily care. Consistency helps maintain healthy skin over time."
            )
        }
    }
}

struct SkinTypeDetailView: View {
    let skinType: String
    @Environment(\.dismiss) private var dismiss
    
    private var info: SkinTypeInfo {
        SkinTypeInfo.getInfo(for: skinType)
    }
    
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
                    SkinTypeHeaderSection(title: info.title)
                    
                    WhatIsItBox(whatIsIt: info.whatIsIt)
                    
                    CharacteristicsSection(characteristics: info.characteristics)
                    
                    Divider()
                    
                    DailyCareSection(tips: info.dailyCareTips)
                    
                    Divider()
                    
                    HabitsToAvoidSection(habits: info.habitsToAvoid)
                    
                    SkinTypeTakeawayBox(takeaway: info.takeaway)
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

struct SkinTypeHeaderSection: View {
    let title: String
    
    private var iconName: String {
        let normalized = title.lowercased()
        if normalized.contains("oily") {
            return "drop"
        } else if normalized.contains("dry") {
            return "water.waves"
        } else {
            return "face.smiling"
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 1.5)
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }
}

struct WhatIsItBox: View {
    let whatIsIt: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 26))
                .foregroundColor(Color(hex: "2596be"))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What is it?")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(whatIsIt)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.75))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "F2F8FB"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2596be").opacity(0.2), lineWidth: 1)
        )
    }
}

struct CharacteristicsSection: View {
    let characteristics: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "4d3865"))
                    .frame(width: 20, alignment: .center)
                
                Text("Common Characteristics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(characteristics, id: \.self) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4d3865").opacity(0.1))
                                .frame(width: 24, height: 24)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Color(hex: "4d3865"))
                        }
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.leading, 28)
        }
    }
}

struct DailyCareSection: View {
    let tips: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 20, alignment: .center)
                
                Text("Daily Care Tips")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.leading, 28)
        }
    }
}

struct HabitsToAvoidSection: View {
    let habits: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.35))
                    .frame(width: 20, alignment: .center)
                
                Text("Habits to Avoid")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                ForEach(habits, id: \.self) { habit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.35))
                            .padding(.top, 2)
                        
                        Text(habit)
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.leading, 28)
        }
    }
}

struct SkinTypeTakeawayBox: View {
    let takeaway: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Takeaway")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.1))
                
                Text(takeaway)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.1).opacity(0.9))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        SkinTypeDetailView(skinType: "Oily")
    }
}
