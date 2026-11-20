import SwiftUI
import AVKit
struct VideoPlayerSurface:View {
    let url:String
    let isActive:Bool
    @State private var player:AVPlayer?
    var body:some View {
        GeometryReader{geo in
            ZStack {
                Color.black
                if let player {PlayerLayerView(player:player).frame(width:geo.size.width,height:geo.size.height)}
                else {ProgressView().tint(.white)}
            }
        }
        .onAppear{configure()}
        .onChange(of:isActive){_,new in if new {player?.play()} else {player?.pause()}}
        .onDisappear{player?.pause();player=nil}
        .onReceive(NotificationCenter.default.publisher(for:.AVPlayerItemDidPlayToEndTime)){notification in
            guard let ended=notification.object as? AVPlayerItem, ended === player?.currentItem else{return}
            player?.seek(to:.zero);if isActive{player?.play()}
        }
    }
    private func configure(){
        guard player == nil, let u=URL(string:url),["https","http"].contains(u.scheme?.lowercased() ?? "") else{return}
        let p=AVPlayer(url:u);p.actionAtItemEnd = .none;player=p
        if isActive {p.play()}
    }
}
private struct PlayerLayerView:UIViewRepresentable {
    let player:AVPlayer
    func makeUIView(context:Context)->PlayerHostView {let view=PlayerHostView();view.playerLayer.player=player;return view}
    func updateUIView(_ uiView:PlayerHostView,context:Context){uiView.playerLayer.player=player}
}
private final class PlayerHostView:UIView {
    override static var layerClass:AnyClass {AVPlayerLayer.self}
    var playerLayer:AVPlayerLayer {layer as! AVPlayerLayer}
    override init(frame:CGRect){super.init(frame:frame);playerLayer.videoGravity = .resizeAspectFill}
    required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
}
