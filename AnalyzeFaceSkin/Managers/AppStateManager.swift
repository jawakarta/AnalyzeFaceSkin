import Combine

import SwiftUI

class AppStateManager: ObservableObject {
    @Published var isCameraReady = false
    @Published var hasAppeared = false

    func markAppeared() {
        hasAppeared = true
    }

    func markCameraReady() {
        isCameraReady = true
    }
}
