import SwiftUI

struct VideoCard: View {
    let video: KovaVideo
    let demoIndex: Int
    let isActive: Bool
    let like: () -> Void
    let bookmark: () -> Void
    let comment: () -> Void
    let report: () -> Void
    let follow: () -> Void
    @State private var paused = false
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if video.isDemo || video.videoUrl.isEmpty {
                demoBackground
            } else {
                VideoPlayerSurface(url: video.videoUrl, isActive: isActive, isPaused: paused)
                    .ignoresSafeArea(edges: .horizontal)
                    .onTapGesture { paused.toggle() }
            }
            LinearGradient(colors: [.clear, .black.opacity(0.08), .black.opacity(0.9)],
                           startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)
            if paused && !video.isDemo {
                Text("PAUSED")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 9) {
                        KovaAvatar(name: video.displayName, size: 32)
                        Text("@" + video.handle).font(.system(size: 15, weight: .bold))
                        if video.isVerified == true {
                            Image(systemName: "checkmark.seal.fill").font(.system(size: 13))
                        }
                    }
                    Text(video.caption).font(.system(size: 14, weight: .medium))
                        .lineLimit(4).fixedSize(horizontal: false, vertical: true)
                    Label(video.musicTitle ?? "Original sound", systemImage: "music.note")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VideoActions(video: video, like: like, bookmark: bookmark, comment: comment, report: report, follow: follow)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .clipped()
        .onChange(of: isActive) { _, isActive in if !isActive { paused = false } }
    }
    private var demoBackground: some View {
        GeometryReader { geo in
            ZStack {
                Color(white: demoIndex.isMultiple(of: 2) ? 0.11 : 0.16)
                VStack(alignment: .leading, spacing: 20) {
                    Text(String(format: "%02d / KOVA", demoIndex + 1))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(["CREATE\nSOMETHING.", "FIND\nYOUR PEOPLE.", "MAKE\nIT YOURS."][demoIndex % 3])
                        .font(.system(size: min(geo.size.width * 0.115, 46), weight: .black))
                        .tracking(-2)
                        .minimumScaleFactor(0.7)
                    Rectangle().fill(.white).frame(width: 68, height: 3)
                    Text("DESIGN PREVIEW · NO LIVE VIDEO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                    Spacer()
                }
                .padding(33)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }
}
