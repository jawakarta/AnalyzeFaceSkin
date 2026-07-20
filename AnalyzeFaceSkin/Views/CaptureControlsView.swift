//
//  CaptureControlsView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI

struct CaptureControlsView: View {
    let onCapture: () -> Void
    let onGallery: () -> Void

    var isCaptureDisabled: Bool = false

    var body: some View {
        HStack(spacing: 40) {
            galleryButton
            
            captureButton
            
            // Invisible placeholder to keep the capture button perfectly centered
            Color.clear
                .frame(width: 50, height: 50)
        }
    }

    private var galleryButton: some View {
        Button(action: onGallery) {
            Image(systemName: "photo.on.rectangle")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                )
        }
        .disabled(isCaptureDisabled)
        .opacity(isCaptureDisabled ? 0.4 : 1.0)
    }
}
