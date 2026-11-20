import SwiftUI
import AVKit
struct VideoPlayerSurface: View {
    let url: String
    let isActive: Bool
    let isPaused: Bool
    @AppStorage("kova.muteVideos") private var muteVideos = true
    @State private var player: AVPlayer?
    init(url: String, isActive: Bool, isPaused: Bool = false) {
        self.url = url; self.isActive = isActive; self.isPaused = isPaused
    }
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                if let player {
                    PlayerLayerView(player: player).frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ProgressView().tint(.white)
                }
            }
        }
        .onAppear { configure() }
        .onChange(of: isActive) { _, _ in syncPlayback() }
        .onChange(of: isPaused) { _, _ in syncPlayback() }
        .onChange(of: muteVideos) { _, new in player?.isMuted = new }
        .onDisappear { player?.pause(); player = nil }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let ended = notification.object as? AVPlayerItem, ended === player?.currentItem else { return }
            player?.seek(to: .zero)
            syncPlayback()
        }
    }
    private func configure() {
        guard player == nil, let url = URL(string: url), url.scheme?.lowercased() == "https" else { return }
        let p = AVPlayer(url: url)
        p.isMuted = muteVideos
        p.actionAtItemEnd = .none
        player = p
        syncPlayback()
    }
    private func syncPlayback() {
        guard let player else { return }
        if isActive && !isPaused { player.play() } else { player.pause() }
    }
}
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> PlayerHostView {
        let view = PlayerHostView()
        view.playerLayer.player = player
        return view
    }
    func updateUIView(_ uiView: PlayerHostView, context: Context) { uiView.playerLayer.player = player }
}
private final class PlayerHostView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override init(frame: CGRect) { super.init(frame: frame); playerLayer.videoGravity = .resizeAspectFill }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
