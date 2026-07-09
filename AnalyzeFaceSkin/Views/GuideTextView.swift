//
//  GuideTextView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI

struct GuideTextView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
    }
}

#Preview {
    GuideTextView(text: "Move Left")
        .preferredColorScheme(.dark)
}
