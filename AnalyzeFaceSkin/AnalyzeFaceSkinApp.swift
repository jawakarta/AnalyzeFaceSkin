//
//  AnalyzeFaceSkinApp.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import SwiftUI
import SwiftData

@main
struct AnalyzeFaceSkinApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(for: SkinAnalysisHistory.self)
    }
}
