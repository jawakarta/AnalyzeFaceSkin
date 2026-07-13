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
    let onSettings: () -> Void
    let onFlash: (() -> Void)?
    let isFlashOn: Bool
    let showFlash: Bool

    var isCaptureDisabled: Bool = false

    var body: some View {
        HStack(spacing: 60) {
            if showFlash {
                flashButton
            } else {
                galleryButton
            }
            captureButton
            settingsButton
        }
    }

    private var flashButton: some View {
        Button(action: { onFlash?() }) {
            Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                .font(.title2)
                .foregroundColor(isFlashOn ? .yellow : .white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
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

    private var settingsButton: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}
