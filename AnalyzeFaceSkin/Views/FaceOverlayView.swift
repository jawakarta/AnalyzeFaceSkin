//
//  FaceOverlayView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI

struct FaceOverlayView: View {
    let faceState: FaceState
    let ovalColor: Color
    let progress: Double

    var body: some View {
        ZStack {
            OvalShape()
                .stroke(ovalColor, lineWidth: 3)
                .frame(width: 250, height: 320)

            ProgressRingView(progress: progress)
                .frame(width: 280, height: 350)
        }
    }
}

struct OvalShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

#Preview {
    FaceOverlayView(
        faceState: FaceState(),
        ovalColor: .green,
        progress: 0.7
    )
}
