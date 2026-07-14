//
//  FaceScanningView.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 13/07/26.
//

import SwiftUI

struct FaceScanningView: View {
    let image: UIImage
    let landmarks: [String: [CGPoint]]
    let analysisResult: SkinAnalysisResult?
    let isAnalyzing: Bool
    
    @State private var scanProgress: CGFloat = 0.0
    @State private var meshOpacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            // Scanning Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isAnalyzing ? Color.pink : Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(isAnalyzing ? (meshOpacity > 0 ? meshOpacity : 0.3) : 1.0)
                
                Text(isAnalyzing ? "Scanning your skin..." : "Skin Analysis Complete")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .bold()
                    .tracking(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isAnalyzing ? Color.pink.opacity(0.5) : Color.green.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: isAnalyzing ? Color.pink.opacity(0.3) : Color.green.opacity(0.3), radius: 6)
            
            // Image with Scan Overlays
            ZStack {
                // Face image (cropped with padding)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    )
                
                // Overlay Effects
                GeometryReader { geo in
                    let size = geo.size
                    
                    // 1. Tech Corner Brackets
                    CornerBracketsShape()
                        .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                        .padding(10)
                    
                    // 2. High-Tech Padded Face Mesh (Jaring-jaring) using actual detected face features
                    if !landmarks.isEmpty {
                        ActualFaceMeshShape(landmarks: landmarks)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.7),
                                        Color.pink.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                            .opacity(meshOpacity)
                            .glow(color: Color.cyan.opacity(0.3), radius: 4)
                        
                        // 3. Glowing Face Mesh Nodes (Intersection Points)
                        FaceMeshNodesView(landmarks: landmarks, size: size)
                            .opacity(meshOpacity)
                    }
                    
                    // 4. Scanning Laser Sweep Line
                    if isAnalyzing {
                        ZStack {
                            // Trail glow
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.pink.opacity(0.2),
                                            Color.pink.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 50)
                            
                            // Laser core
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan,
                                            Color.pink,
                                            Color.cyan
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 3)
                                .shadow(color: Color.pink, radius: 8)
                        }
                        .frame(width: size.width)
                        .position(x: size.width / 2, y: scanProgress * size.height)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 420)
            .padding(.horizontal, 20)
            
            // Result Card
            if let result = analysisResult, let type = result.skinType {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SKIN TYPE DETECTED")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.cyan)
                                .bold()
                                .tracking(2)
                            
                            Text(type.capitalized)
                                .font(.system(.title2, design: .rounded))
                                .foregroundColor(.white)
                                .bold()
                        }
                        
                        Spacer()
                        
                        if let confidence = result.skinTypeConfidence {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("ACCURACY")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.pink)
                                    .bold()
                                    .tracking(2)
                                
                                Text(String(format: "%.0f%%", confidence * 100))
                                    .font(.system(.title2, design: .monospaced))
                                    .foregroundColor(.pink)
                                    .bold()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.cyan.opacity(0.3), Color.pink.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Smooth infinite sweep animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                scanProgress = 1.0
            }
            
            // Dynamic pulse animation for the mesh/nodes opacity
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                meshOpacity = 0.8
            }
        }
    }
}

// Custom Shape to draw tech corner brackets
struct CornerBracketsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 20
        
        // Top Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        // Top Right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        // Bottom Left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        
        // Bottom Right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        
        return path
    }
}

// Custom Shape representing facial mesh connections based on real detected landmarks
struct ActualFaceMeshShape: Shape {
    let landmarks: [String: [CGPoint]]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !landmarks.isEmpty else { return path }
        
        // Helper to map 0..1 point to rect bounds
        func point(for pt: CGPoint) -> CGPoint {
            CGPoint(x: pt.x * rect.width, y: pt.y * rect.height)
        }
        
        // 1. Contour
        if let contour = landmarks["contour"], !contour.isEmpty {
            path.move(to: point(for: contour[0]))
            for i in 1..<contour.count {
                path.addLine(to: point(for: contour[i]))
            }
        }
        
        // 2. Eyebrows
        if let leftEyebrow = landmarks["leftEyebrow"], !leftEyebrow.isEmpty {
            path.move(to: point(for: leftEyebrow[0]))
            for i in 1..<leftEyebrow.count {
                path.addLine(to: point(for: leftEyebrow[i]))
            }
        }
        if let rightEyebrow = landmarks["rightEyebrow"], !rightEyebrow.isEmpty {
            path.move(to: point(for: rightEyebrow[0]))
            for i in 1..<rightEyebrow.count {
                path.addLine(to: point(for: rightEyebrow[i]))
            }
        }
        
        // 3. Eyes (closed loops)
        if let leftEye = landmarks["leftEye"], !leftEye.isEmpty {
            path.move(to: point(for: leftEye[0]))
            for i in 1..<leftEye.count {
                path.addLine(to: point(for: leftEye[i]))
            }
            path.closeSubpath()
        }
        if let rightEye = landmarks["rightEye"], !rightEye.isEmpty {
            path.move(to: point(for: rightEye[0]))
            for i in 1..<rightEye.count {
                path.addLine(to: point(for: rightEye[i]))
            }
            path.closeSubpath()
        }
        
        // 4. Nose & Nose Crest
        if let nose = landmarks["nose"], !nose.isEmpty {
            path.move(to: point(for: nose[0]))
            for i in 1..<nose.count {
                path.addLine(to: point(for: nose[i]))
            }
        }
        if let noseCrest = landmarks["noseCrest"], !noseCrest.isEmpty {
            path.move(to: point(for: noseCrest[0]))
            for i in 1..<noseCrest.count {
                path.addLine(to: point(for: noseCrest[i]))
            }
        }
        
        // 5. Lips (closed loops)
        if let outerLips = landmarks["outerLips"], !outerLips.isEmpty {
            path.move(to: point(for: outerLips[0]))
            for i in 1..<outerLips.count {
                path.addLine(to: point(for: outerLips[i]))
            }
            path.closeSubpath()
        }
        
        // 6. Cross-connections forming the high-tech mesh (jaring-jaring)
        if let leftEye = landmarks["leftEye"], let noseCrest = landmarks["noseCrest"], !leftEye.isEmpty, !noseCrest.isEmpty {
            let eyeCenter = average(leftEye)
            let noseTop = noseCrest[0]
            path.move(to: point(for: eyeCenter))
            path.addLine(to: point(for: noseTop))
        }
        
        if let rightEye = landmarks["rightEye"], let noseCrest = landmarks["noseCrest"], !rightEye.isEmpty, !noseCrest.isEmpty {
            let eyeCenter = average(rightEye)
            let noseTop = noseCrest[0]
            path.move(to: point(for: eyeCenter))
            path.addLine(to: point(for: noseTop))
        }
        
        if let leftEye = landmarks["leftEye"], let leftEyebrow = landmarks["leftEyebrow"], !leftEye.isEmpty, !leftEyebrow.isEmpty {
            path.move(to: point(for: average(leftEye)))
            path.addLine(to: point(for: average(leftEyebrow)))
        }
        
        if let rightEye = landmarks["rightEye"], let rightEyebrow = landmarks["rightEyebrow"], !rightEye.isEmpty, !rightEyebrow.isEmpty {
            path.move(to: point(for: average(rightEye)))
            path.addLine(to: point(for: average(rightEyebrow)))
        }
        
        if let nose = landmarks["nose"], let outerLips = landmarks["outerLips"], !nose.isEmpty, !outerLips.isEmpty {
            let noseBottom = nose[nose.count / 2]
            let lipTop = outerLips[0]
            path.move(to: point(for: noseBottom))
            path.addLine(to: point(for: lipTop))
        }
        
        // Connect contours to cheeks/mouth for mesh styling
        if let contour = landmarks["contour"], contour.count > 16 {
            if let leftEye = landmarks["leftEye"], !leftEye.isEmpty {
                path.move(to: point(for: contour[2]))
                path.addLine(to: point(for: leftEye[0]))
            }
            if let rightEye = landmarks["rightEye"], !rightEye.isEmpty {
                path.move(to: point(for: contour[14]))
                path.addLine(to: point(for: rightEye[rightEye.count / 2]))
            }
            if let outerLips = landmarks["outerLips"], !outerLips.isEmpty {
                path.move(to: point(for: contour[5]))
                path.addLine(to: point(for: outerLips[0]))
                
                path.move(to: point(for: contour[11]))
                path.addLine(to: point(for: outerLips[outerLips.count / 2]))
            }
        }
        
        return path
    }
    
    private func average(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.map { $0.x }.reduce(0, +)
        let sumY = points.map { $0.y }.reduce(0, +)
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
}

// Glowing face nodes mapped to actual coordinates
struct FaceMeshNodesView: View {
    let landmarks: [String: [CGPoint]]
    let size: CGSize
    
    var body: some View {
        ForEach(Array(landmarks.keys), id: \.self) { key in
            if let points = landmarks[key] {
                ForEach(0..<points.count, id: \.self) { idx in
                    let pos = points[idx]
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 4, height: 4)
                        .position(x: pos.x * size.width, y: pos.y * size.height)
                        .shadow(color: Color.cyan, radius: 4)
                }
            }
        }
    }
}

#Preview {
    FaceScanningView(image: UIImage(), landmarks: [:], analysisResult: nil, isAnalyzing: true)
}

// Glow effect extension
extension View {
    func glow(color: Color = .red, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color, radius: radius)
            .shadow(color: color, radius: radius / 2)
    }
}
