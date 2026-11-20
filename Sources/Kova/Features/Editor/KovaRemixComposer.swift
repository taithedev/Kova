import Foundation
import AVFoundation

struct KovaRemixIntent: Identifiable {
    let id = UUID()
    let sourceID: String
    let sourceHandle: String
    let kind: String
}

@MainActor final class KovaRemixCoordinator: ObservableObject {
    @Published var intent: KovaRemixIntent?

    func start(_ video: KovaVideo, kind: String) {
        guard video.allowRemix == true, video.visibility == "public",
              ["stitch","duet"].contains(kind) else { return }
        intent = KovaRemixIntent(sourceID: video.id, sourceHandle: video.handle, kind: kind)
    }

    func clear() { intent = nil }
}

/// Creator-consented and public-only source checked again at publish time.
/// Stitches source then creator; duets render two videos simultaneously.
enum KovaRemixComposer {
    static func make(kind: String, sourceURL: URL, creatorURL: URL) async throws -> URL {
        let source = AVURLAsset(url: sourceURL)
        let creator = AVURLAsset(url: creatorURL)
        let originalDuration = try await source.load(.duration)
        let creatorDuration = try await creator.load(.duration)
        guard let sourceTrack = try await source.loadTracks(withMediaType: .video).first,
              let creatorTrack = try await creator.loadTracks(withMediaType: .video).first else {
            throw APIError.server("Both videos need a valid video track.")
        }

        let sourceSeconds = min(CMTimeGetSeconds(originalDuration),
                                kind == "stitch" ? 4 : 20)
        let creatorSeconds = min(CMTimeGetSeconds(creatorDuration), 50)
        guard sourceSeconds >= 1, creatorSeconds >= 1 else {
            throw APIError.server("Remixing needs clips at least 1 second long.")
        }
        let sourceTime = CMTime(seconds: sourceSeconds, preferredTimescale: 600)
        let localTime = CMTime(seconds: creatorSeconds, preferredTimescale: 600)
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: 720, height: 1280)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        if kind == "stitch" {
            guard let track = composition.addMutableTrack(withMediaType: .video,
                            preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw APIError.server("Unable to create a Stitch track.")
            }
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: sourceTime),
                                      of: sourceTrack, at: .zero)
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: localTime),
                                      of: creatorTrack, at: sourceTime)
            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            layer.setTransform(try await transform(for: sourceTrack,
                               into: CGRect(x: 0, y: 0, width: 720, height: 1280)),
                               at: .zero)
            layer.setTransform(try await transform(for: creatorTrack,
                               into: CGRect(x: 0, y: 0, width: 720, height: 1280)),
                               at: sourceTime)
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero,
                                                duration: CMTimeAdd(sourceTime, localTime))
            instruction.layerInstructions = [layer]
            videoComposition.instructions = [instruction]
            await addAudio(from: source, to: composition, at: .zero, duration: sourceTime)
            await addAudio(from: creator, to: composition, at: sourceTime, duration: localTime)
        } else {
            let duration = CMTimeMinimum(sourceTime, localTime)
            guard let left = composition.addMutableTrack(withMediaType: .video,
                               preferredTrackID: kCMPersistentTrackID_Invalid),
                  let right = composition.addMutableTrack(withMediaType: .video,
                               preferredTrackID: kCMPersistentTrackID_Invalid) else {
                throw APIError.server("Unable to create Duet tracks.")
            }
            try left.insertTimeRange(CMTimeRange(start: .zero, duration: duration),
                                     of: sourceTrack, at: .zero)
            try right.insertTimeRange(CMTimeRange(start: .zero, duration: duration),
                                      of: creatorTrack, at: .zero)
            let leftLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: left)
            let rightLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: right)
            leftLayer.setTransform(try await transform(for: sourceTrack,
                       into: CGRect(x: 0, y: 0, width: 360, height: 1280)), at: .zero)
            rightLayer.setTransform(try await transform(for: creatorTrack,
                        into: CGRect(x: 360, y: 0, width: 360, height: 1280)), at: .zero)
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
            instruction.layerInstructions = [rightLayer, leftLayer]
            videoComposition.instructions = [instruction]
            await addAudio(from: source, to: composition, at: .zero, duration: duration)
            await addAudio(from: creator, to: composition, at: .zero, duration: duration)
        }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("kova-remix-" + UUID().uuidString)
            .appendingPathExtension("mp4")
        guard let exporter = AVAssetExportSession(
            asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw APIError.server("Could not initialize remix rendering.")
        }
        exporter.outputURL = output
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: exporter.error ??
                        APIError.server("Remix export failed. Try a shorter clip."))
                }
            }
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
        let bytes = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard bytes > 0 && bytes <= 100 * 1024 * 1024 else {
            try? FileManager.default.removeItem(at: output)
            throw APIError.server("Remix is too large. Record a shorter clip.")
        }
        return output
    }

    private static func transform(for track: AVAssetTrack,
                                  into area: CGRect) async throws -> CGAffineTransform {
        let naturalSize = try await track.load(.naturalSize)
        let preferred = try await track.load(.preferredTransform)
        let bounds = CGRect(origin: .zero, size: naturalSize).applying(preferred)
        let w = max(1, abs(bounds.width))
        let h = max(1, abs(bounds.height))
        // Fill the canvas, crop in the center for tall portrait content.
        let scale = max(area.width / w, area.height / h)
        return preferred
            .concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(
                translationX: area.minX + (area.width - w * scale) * 0.5,
                y: area.minY + (area.height - h * scale) * 0.5))
    }

    private static func addAudio(from source: AVURLAsset, to composition: AVMutableComposition,
                                 at position: CMTime, duration: CMTime) async {
        guard let track = try? await source.loadTracks(withMediaType: .audio).first,
              let output = composition.addMutableTrack(withMediaType: .audio,
                      preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        try? output.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: track, at: position)
    }
}
