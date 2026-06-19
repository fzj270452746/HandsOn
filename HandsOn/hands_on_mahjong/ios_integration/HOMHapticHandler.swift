// HOMHapticHandler.swift
// Core Haptics 实现 - 复制到宿主 iOS 项目

import CoreHaptics
import Flutter

final class HOMHapticHandler {
    static let shared = HOMHapticHandler()

    private var engine: CHHapticEngine?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        try? engine?.start()
    }

    func handle(call: FlutterMethodCall, result: FlutterResult) {
        guard let engine else { result(FlutterMethodNotImplemented); return }
        let args = call.arguments as? [String: Any] ?? [:]
        let intensity = args["intensity"] as? Float ?? 0.8

        switch call.method {
        case "scrub":
            let suit = args["suit"] as? String ?? "wan"
            playScrub(suit: suit, intensity: intensity)
        case "flipCorrect":
            play(events: [(time: 0, intensity: intensity, sharpness: 0.8)])
        case "flipWrong":
            play(events: [
                (time: 0, intensity: intensity, sharpness: 0.2),
                (time: 0.15, intensity: intensity * 0.8, sharpness: 0.2),
            ])
        case "lockSuccess":
            play(events: [
                (time: 0, intensity: intensity * 0.7, sharpness: 0.6),
                (time: 0.1, intensity: intensity * 0.7, sharpness: 0.6),
            ])
        case "tenpai":
            play(events: [(time: 0, intensity: intensity * 0.3, sharpness: 0.3)])
        case "levelWon":
            play(events: [
                (time: 0, intensity: 0.5, sharpness: 0.7),
                (time: 0.15, intensity: 0.75, sharpness: 0.8),
                (time: 0.3, intensity: 1.0, sharpness: 0.9),
            ])
        case "levelLost":
            play(events: [(time: 0, intensity: 1.0, sharpness: 0.1)])
        default:
            break
        }
        result(nil)
    }

    private func playScrub(suit: String, intensity: Float) {
        let sharpness: Float = suit == "tiao" ? 0.5 : suit == "tong" ? 0.8 : 0.3
        guard let event = try? CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0,
            duration: 0.05
        ) else { return }
        try? play(events: [event])
    }

    private func play(events: [(time: Double, intensity: Float, sharpness: Float)]) {
        let hapticEvents: [CHHapticEvent] = events.compactMap { e in
            try? CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: e.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: e.sharpness),
                ],
                relativeTime: e.time
            )
        }
        try? play(events: hapticEvents)
    }

    private func play(events: [CHHapticEvent]) throws {
        guard let engine else { return }
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)
    }
}
