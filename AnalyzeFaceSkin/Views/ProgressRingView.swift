//
//  ProgressRingView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI

struct ProgressRingView: View {
    let progress: Double

    private let lineWidth: CGFloat = 5
    private let progressColor = Color(hex: "E5B4D6") // Pastel Pink / Lavender from the screenshot

    var body: some View {
        ZStack {
            // Background guide: dashed pastel pink
            OvalProgressShape(progress: 1.0)
                .stroke(
                    progressColor.opacity(0.4),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [12, 8])
                )
 
            // Active progress track: solid glowing pastel pink
            OvalProgressShape(progress: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth + 0.5, lineCap: .round)
                )
                .shadow(color: progressColor.opacity(0.6), radius: 6)
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}
 
struct OvalProgressShape: Shape {
    var progress: Double
 
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
 
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0.0 else { return path }
        
        let center = CGPoint(x: 0.5, y: 0.5)
        let radius: CGFloat = 0.5
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees(-90 + 360 * progress)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        let scaleTransform = CGAffineTransform(scaleX: rect.width, y: rect.height)
        return path.applying(scaleTransform)
    }
}

#Preview {
    ProgressRingView(progress: 0.5)
        .frame(width: 100, height: 100)
}
