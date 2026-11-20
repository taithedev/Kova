import Foundation
import AVFoundation

/// Small original synthesized loops that ship as code rather than third-party
/// copyrighted music. Each one is generated locally on the user's phone.
enum KovaOriginalSound: String, CaseIterable, Identifiable {
    case none = "Original only"
    case orbit = "Orbit"
    case shimmer = "Shimmer"
    case pulse = "Pulse"
    case drift = "Drift"

    var id: String { rawValue }
    var credit: String {
        self == .none ? "Original audio" : "Kova Original · " + rawValue
    }

    func makeAudioURL() throws -> URL? {
        guard self != .none else { return nil }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("kova-sound-" + UUID().uuidString)
            .appendingPathExtension("wav")
        let sampleRate = 44_100
        let seconds = 16
        let count = sampleRate * seconds
        let sequence: [Double]
        switch self {
        case .orbit: sequence = [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 392.0]
        case .shimmer: sequence = [523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 783.99, 987.77]
        case .pulse: sequence = [130.81, 130.81, 196.0, 164.81, 130.81, 146.83, 196.0, 130.81]
        case .drift: sequence = [220.0, 277.18, 329.63, 277.18, 246.94, 293.66, 369.99, 293.66]
        case .none: return nil
        }
        var samples = [Int16](repeating: 0, count: count)
        for index in 0..<count {
            let t = Double(index) / Double(sampleRate)
            let step = Int(t * 2.0) % sequence.count
            let frequency = sequence[step]
            let fraction = (t * 2.0).truncatingRemainder(dividingBy: 1)
            let fade = min(1.0, fraction * 25) * exp(-1.15 * fraction)
            let primary = sin(2 * .pi * frequency * t)
            let harmonic = sin(2 * .pi * frequency * 2 * t) * 0.13
            let bass = sin(2 * .pi * frequency * 0.5 * t) * 0.17
            let waveform = (primary * 0.34 + harmonic + bass) * fade
            samples[index] = Int16(max(-28_000, min(28_000, waveform * 20_000)))
        }

        var data = Data(capacity: 44 + count * MemoryLayout<Int16>.size)
        func chunk(_ string: String) { data.append(contentsOf: string.utf8) }
        func word(_ value: UInt16) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        func dword(_ value: UInt32) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        let size = UInt32(count * 2)
        chunk("RIFF")
        dword(36 + size)
        chunk("WAVE")
        chunk("fmt ")
        dword(16)
        word(1)
        word(1)
        dword(UInt32(sampleRate))
        dword(UInt32(sampleRate * 2))
        word(2)
        word(16)
        chunk("data")
        dword(size)
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        try data.write(to: output, options: .atomic)
        return output
    }
}
