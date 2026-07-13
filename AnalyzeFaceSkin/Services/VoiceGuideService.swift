//
//  VoiceGuideService.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
//

import AVFoundation

class VoiceGuideService {
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenText: String = ""
    private var lastSpokenTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 2.0

    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSpokenTime) > minimumInterval else {
            return
        }

        lastSpokenText = text
        lastSpokenTime = now

        // Configure audio session to bypass silent switch and mix with active camera capture session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}
