//
//  FaceAlignmentHelpers.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import Foundation
import Vision

enum FaceAlignmentConstants {
    static let centerXRange: ClosedRange<CGFloat> = 0.35...0.65
    static let centerYRange: ClosedRange<CGFloat> = 0.35...0.65
    static let faceWidthRange: ClosedRange<CGFloat> = 0.2...0.5
    static let maxRoll: Float = 0.25
    static let maxYaw: Float = 0.3
    static let maxPitch: Float = 0.3
    static let stabilityDuration: TimeInterval = 2.0
}

enum FaceAlignmentHelpers {
    static func isCentered(_ boundingBox: CGRect) -> Bool {
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        return FaceAlignmentConstants.centerXRange.contains(centerX)
            && FaceAlignmentConstants.centerYRange.contains(centerY)
    }

    static func isValidDistance(_ boundingBox: CGRect) -> Bool {
        FaceAlignmentConstants.faceWidthRange.contains(boundingBox.width)
    }

    static func isValidRotation(pitch: NSNumber?, roll: NSNumber?, yaw: NSNumber?) -> Bool {
        guard let roll = roll?.floatValue,
              let yaw = yaw?.floatValue,
              let pitch = pitch?.floatValue else {
            return false
        }
        return abs(roll) < FaceAlignmentConstants.maxRoll
            && abs(yaw) < FaceAlignmentConstants.maxYaw
            && abs(pitch) < FaceAlignmentConstants.maxPitch
    }

    static func determineGuideText(from faceState: FaceState) -> String {
        guard faceState.isDetected else {
            return "Move your face into frame"
        }

        let bbox = faceState.boundingBox
        let centerX = bbox.midX
        let centerY = bbox.midY

        if !FaceAlignmentConstants.centerXRange.contains(centerX) {
            return centerX < 0.35 ? "Move Right" : "Move Left"
        }

        if !FaceAlignmentConstants.centerYRange.contains(centerY) {
            return centerY < 0.35 ? "Move Down" : "Move Up"
        }

        if bbox.width < FaceAlignmentConstants.faceWidthRange.lowerBound {
            return "Move Closer"
        }
        if bbox.width > FaceAlignmentConstants.faceWidthRange.upperBound {
            return "Move Back"
        }

        if let yaw = faceState.yaw?.floatValue, abs(yaw) > FaceAlignmentConstants.maxYaw {
            return "Look Straight"
        }

        if let pitch = faceState.pitch?.floatValue, abs(pitch) > FaceAlignmentConstants.maxPitch {
            return "Look Straight"
        }

        if let roll = faceState.roll?.floatValue, abs(roll) > FaceAlignmentConstants.maxRoll {
            return "Hold Still"
        }

        return faceState.isAligned ? "Ready" : "Hold Still"
    }
}
