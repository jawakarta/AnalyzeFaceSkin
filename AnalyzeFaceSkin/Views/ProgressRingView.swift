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
    private let neonGreen = Color(red: 57/255, green: 255/255, blue: 20/255)

    var body: some View {
        ZStack {
            OvalProgressShape(progress: 1.0)
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
 
            OvalProgressShape(progress: progress)
                .stroke(neonGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .shadow(color: neonGreen.opacity(0.6), radius: 5)
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
