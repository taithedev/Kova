import SwiftUI
import AVFoundation
import AVKit
import CoreImage
import UIKit
import UniformTypeIdentifiers

enum KovaVideoFilter: String, CaseIterable {
    case original = "Original"
    case mono = "Mono"
    case warm = "Warm"
    case cool = "Cool"
    case vivid = "Vivid"
    case soft = "Soft"

    func render(_ image: CIImage) -> CIImage {
        switch self {
        case .original: return image
        case .mono: return image.applyingFilter("CIPhotoEffectMono")
        case .warm: return image.applyingFilter("CIPhotoEffectTransfer")
        case .cool: return image.applyingFilter("CIPhotoEffectProcess")
        case .vivid: return image.applyingFilter("CIPhotoEffectChrome")
        case .soft: return image.applyingFilter("CIColorControls",
                                                parameters: [kCIInputSaturationKey: 0.82,
                                                             kCIInputContrastKey: 0.92])
        }
    }
}

/// Exports real edits into a new MP4. It doesn't modify the original recording.
enum KovaVideoExporter {
    struct Options {
        let start: Double
        let end: Double
        let filter: KovaVideoFilter
        let text: String
        let sticker: String
        let mute: Bool
        let textColor: UIColor
        let audioURL: URL?
    }
    static func makeOverlay(options: Options) -> CIImage? {
        let body = ([options.text, options.sticker].filter { !$0.isEmpty }).joined(separator: "  ")
        guard !body.isEmpty else { return nil }
        let size = CGSize(width: 1000, height: 230)
        let rendered = UIGraphicsImageRenderer(size: size).image { context in
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 65, weight: .heavy),
                .foregroundColor: options.textColor,
                .paragraphStyle: paragraph,
                .strokeColor: UIColor.black,
                .strokeWidth: -3
            ]
            let drawing = NSString(string: String(body.prefix(140)))
            drawing.draw(in: CGRect(x: 25, y: 24, width: 950, height: 180),
                         withAttributes: attributes)
        }
        return CIImage(image: rendered)
    }

    static func export(inputURL: URL, options: Options) async throws -> URL {
        let asset = AVURLAsset(url: inputURL)
        var renderedAsset: AVAsset = asset
        if let audioURL = options.audioURL {
            let sourceDuration = try await asset.load(.duration)
            let composition = AVMutableComposition()
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first,
                  let outputTrack = composition.addMutableTrack(withMediaType: .video,
                      preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw APIError.server("This video has no editable video track.")
            }
            try outputTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: sourceDuration),
                of: videoTrack, at: .zero
            )
            outputTrack.preferredTransform = try await videoTrack.load(.preferredTransform)
            if !options.mute,
               let existingAudio = try await asset.loadTracks(withMediaType: .audio).first,
               let existingTarget = composition.addMutableTrack(withMediaType: .audio,
                   preferredTrackID: kCMPersistentTrackID_Invalid) {
                try existingTarget.insertTimeRange(
                    CMTimeRange(start: .zero, duration: sourceDuration),
                    of: existingAudio, at: .zero
                )
            }
            let music = AVURLAsset(url: audioURL)
            guard let audioTrack = try await music.loadTracks(withMediaType: .audio).first else {
                throw APIError.server("The selected sound doesn't contain audio.")
            }
            let musicDuration = try await music.load(.duration)
            guard CMTimeCompare(musicDuration, .zero) > 0 else {
                throw APIError.server("This audio track is empty.")
            }
            if let target = composition.addMutableTrack(withMediaType: .audio,
                              preferredTrackID: kCMPersistentTrackID_Invalid) {
                var position = CMTime.zero
                while CMTimeCompare(position, sourceDuration) < 0 {
                    let left = CMTimeSubtract(sourceDuration, position)
                    let segment = CMTimeMinimum(left, musicDuration)
                    try target.insertTimeRange(
                        CMTimeRange(start: .zero, duration: segment),
                        of: audioTrack, at: position
                    )
                    position = CMTimeAdd(position, segment)
                }
            }
            renderedAsset = composition
        }
        guard let exporter = AVAssetExportSession(asset: renderedAsset,
                                                  presetName: AVAssetExportPresetHighestQuality) else {
            throw APIError.server("The selected video cannot be exported.")
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("kova-edited-" + UUID().uuidString)
            .appendingPathExtension("mp4")
        exporter.outputURL = output
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        let start = max(0, options.start)
        let duration = max(0.1, options.end - start)
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )

        let overlay = makeOverlay(options: options)
        let filter = options.filter
        if filter != .original || overlay != nil {
            exporter.videoComposition = AVVideoComposition(
                asset: renderedAsset,
                applyingCIFiltersWithHandler: { request in
                    let base = request.sourceImage
                    var output = filter.render(base.clampedToExtent())
                    if let overlay {
                        let scale = min(base.extent.width / overlay.extent.width * 0.9, 2)
                        let scaled = overlay.transformed(by:
                            CGAffineTransform(scaleX: scale, y: scale))
                        let location = CGAffineTransform(
                            translationX: base.extent.midX - scaled.extent.width * 0.5,
                            y: base.extent.minY + base.extent.height * 0.12
                        )
                        output = scaled.transformed(by: location).composited(over: output)
                    }
                    request.finish(with: output.cropped(to: base.extent), context: nil)
                }
            )
        }
        if options.mute && options.audioURL == nil {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            if let audio = audioTracks.first {
                let parameters = AVMutableAudioMixInputParameters(track: audio)
                parameters.setVolume(0, at: .zero)
                let mix = AVMutableAudioMix()
                mix.inputParameters = [parameters]
                exporter.audioMix = mix
            }
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: exporter.error ??
                        APIError.server("The video export did not finish."))
                }
            }
        }
        let data = try FileManager.default.attributesOfItem(atPath: output.path)
        guard let size = data[.size] as? NSNumber, size.intValue > 0 else {
            throw APIError.server("Video editing created an empty file.")
        }
        guard size.intValue <= 100 * 1024 * 1024 else {
            try? FileManager.default.removeItem(at: output)
            throw APIError.server("The edited video is over 100 MB. Trim it shorter.")
        }
        return output
    }
}

struct KovaEditingInput: Identifiable {
    let id = UUID()
    let url: URL
    let initialFilter: KovaVideoFilter
}

struct KovaEditorView: View {
    let input: KovaEditingInput
    let onExport: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var duration = 30.0
    @State private var start = 0.0
    @State private var end = 30.0
    @State private var filter = KovaVideoFilter.original
    @State private var overlayText = ""
    @State private var sticker = ""
    @State private var selectedColor = "White"
    @State private var mute = false
    @State private var selectedSound = KovaOriginalSound.none
    @State private var importedSoundURL: URL?
    @State private var importedSoundTitle: String?
    @State private var importSound = false
    @State private var busy = false
    @State private var errorMessage: String?
    @FocusState private var textFocused: Bool

    private let stickers = ["", "✨", "⭐", "❤️", "🎮", "🎵", "🔥", "🌈", "😂"]
    private var ink: UIColor {
        switch selectedColor {
        case "Yellow": return .systemYellow
        case "Blue": return .systemCyan
        case "Pink": return .systemPink
        default: return .white
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.black)
                        if let player {
                            VideoPlayer(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .saturation(filter == .mono ? 0 : (filter == .vivid ? 1.35 : 1))
                        } else {
                            ProgressView()
                        }
                        VStack {
                            Spacer()
                            if !overlayText.isEmpty || !sticker.isEmpty {
                                Text(overlayText + " " + sticker)
                                    .font(.system(size: 21, weight: .heavy))
                                    .foregroundStyle(Color(uiColor: ink))
                                    .shadow(color: .black, radius: 5)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 35)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .frame(height: 335)

                    HStack(spacing: 12) {
                        Label("Clip editor", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1fs / %.1fs", end - start, duration))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(KovaTheme.muted)
                    }

                    GroupBox("Trim beginning and end") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Start").font(.caption)
                                Slider(value: $start,
                                       in: 0...max(0, end - 1), step: 0.1)
                                Text(String(format: "%.1f", start))
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 40)
                            }
                            HStack {
                                Text("End").font(.caption)
                                Slider(value: $end,
                                       in: min(duration, start + 1)...max(1, duration),
                                       step: 0.1)
                                Text(String(format: "%.1f", end))
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 40)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("COLOR FILTERS").font(.caption.bold())
                            .foregroundStyle(KovaTheme.muted)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(KovaVideoFilter.allCases, id: \.self) { option in
                                    Button(option.rawValue) { filter = option }
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 14).padding(.vertical, 11)
                                        .background(filter == option ? KovaTheme.accent : KovaTheme.panel,
                                                    in: Capsule())
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 11) {
                        Text("ON-SCREEN TEXT").font(.caption.bold())
                            .foregroundStyle(KovaTheme.muted)
                        TextField("Add a title, caption or phrase", text: $overlayText)
                            .textFieldStyle(.roundedBorder)
                            .focused($textFocused)
                            .onChange(of: overlayText) { _, value in
                                if value.count > 100 { overlayText = String(value.prefix(100)) }
                            }
                        HStack {
                            ForEach(["White", "Yellow", "Blue", "Pink"], id: \.self) { color in
                                Button(color) { selectedColor = color }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 11).padding(.vertical, 8)
                                    .background(selectedColor == color ? KovaTheme.accent : KovaTheme.panel,
                                                in: Capsule())
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STICKERS").font(.caption.bold())
                            .foregroundStyle(KovaTheme.muted)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(stickers, id: \.self) { value in
                                    Button(value.isEmpty ? "None" : value) { sticker = value }
                                        .font(.system(size: 24))
                                        .frame(minWidth: 49, minHeight: 49)
                                        .background(sticker == value ? KovaTheme.raised : KovaTheme.panel,
                                                    in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SOUND STUDIO").font(.caption.bold())
                            .foregroundStyle(KovaTheme.muted)
                        Picker("Soundtrack", selection: $selectedSound) {
                            ForEach(KovaOriginalSound.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        .pickerStyle(.menu)
                        Button {
                            importSound = true
                        } label: {
                            Label("Import a sound I own", systemImage: "waveform.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        if let importedSoundTitle {
                            Text("Selected file: " + importedSoundTitle)
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                            Button("Use an original Kova sound instead") {
                                importedSoundTitle = nil
                                importedSoundURL = nil
                            }
                            .font(.caption)
                        }
                        Text("Original Kova loops are generated locally. Only import audio you created or have permission to use.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    Toggle(isOn: $mute) {
                        Label("Remove original video audio", systemImage: "speaker.slash")
                    }
                    .tint(KovaTheme.accent)
                    Text("Effects, text and stickers are permanently rendered into the exported video. Your original recording is kept unchanged.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                    Button {
                        Task { await finish() }
                    } label: {
                        HStack {
                            Spacer()
                            if busy { ProgressView().padding(.trailing, 10) }
                            Label(busy ? "Rendering video…" : "Apply edits", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .padding(9)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KovaTheme.accent)
                    .disabled(busy || end - start < 1)
                }
                .padding(17)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KovaTheme.background)
            .navigationTitle("Edit video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.disabled(busy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        start = 0; end = duration; filter = .original
                        overlayText = ""; sticker = ""; mute = false
                        selectedSound = .none; importedSoundURL = nil; importedSoundTitle = nil
                    }
                    .disabled(busy)
                }
            }
            .task { await prepare() }
            .onDisappear { player?.pause() }
            .onChange(of: mute) { _, value in player?.isMuted = value }
            .fileImporter(isPresented: $importSound, allowedContentTypes: [.audio]) { result in
                do {
                    let url = try result.get()
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    let bytes = (attributes[.size] as? NSNumber)?.intValue ?? 0
                    guard bytes > 0 && bytes < 25_000_000 else {
                        throw APIError.server("Select an audio file smaller than 25 MB.")
                    }
                    let imported = FileManager.default.temporaryDirectory
                        .appendingPathComponent("kova-audio-" + UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    try FileManager.default.copyItem(at: url, to: imported)
                    importedSoundURL = imported
                    importedSoundTitle = url.deletingPathExtension().lastPathComponent
                } catch { errorMessage = error.localizedDescription }
            }
        }
    }

    private func prepare() async {
        filter = input.initialFilter
        let asset = AVURLAsset(url: input.url)
        if let seconds = try? await asset.load(.duration).seconds, seconds >= 1 {
            duration = min(seconds, 600)
            end = duration
        }
        let p = AVPlayer(url: input.url)
        p.isMuted = mute
        player = p
    }

    private func finish() async {
        guard !busy, end - start >= 1 else { return }
        busy = true
        errorMessage = nil
        defer { busy = false }
        player?.pause()
        do {
            let musicURL = importedSoundURL ?? selectedSound.makeAudioURL()
            let soundCredit = importedSoundTitle.map { "User sound · " + $0 } ?? selectedSound.credit
            let options = KovaVideoExporter.Options(
                start: start, end: end, filter: filter,
                text: overlayText.trimmingCharacters(in: .whitespacesAndNewlines),
                sticker: sticker, mute: mute, textColor: ink, audioURL: musicURL
            )
            let output = try await KovaVideoExporter.export(inputURL: input.url, options: options)
            onExport(output, soundCredit)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
