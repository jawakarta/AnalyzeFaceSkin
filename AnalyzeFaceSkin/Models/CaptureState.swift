//
//  CaptureState.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import Foundation
import UIKit

enum CaptureState: Equatable {
    case idle
    case detecting
    case aligning
    case ready
    case capturing
    case captured(UIImage)

    static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.detecting, .detecting), (.aligning, .aligning),
            (.ready, .ready), (.capturing, .capturing):
            return true
        case (.captured, .captured):
            return true
        default:
            return false
        }
    }
}
