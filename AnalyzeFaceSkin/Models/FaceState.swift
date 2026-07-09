//
//  FaceState.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import Foundation
import CoreGraphics

struct FaceState {
    var isDetected = false
    var boundingBox: CGRect = .zero
    var pitch: NSNumber?
    var roll: NSNumber?
    var yaw: NSNumber?
    var isCentered = false
    var isValidDistance = false
    var isValidRotation = false

    var isAligned: Bool {
        isCentered && isValidDistance && isValidRotation
    }
}
