import SwiftUI
struct VideoCard:View {
    let video:KovaVideo
    let demoIndex:Int
    let isActive:Bool
    let like:()->Void
    let bookmark:()->Void
    let comment:()->Void
    let report:()->Void
    let follow:()->Void
    var body:some View {
        ZStack(alignment:.bottomLeading) {
            if video.isDemo || video.videoUrl.isEmpty {
                demoBackground
            } else {
                VideoPlayerSurface(url:video.videoUrl,isActive:isActive).ignoresSafeArea(edges:.horizontal)
            }
            LinearGradient(colors:[.clear,.black.opacity(0.03),.black.opacity(0.88)],startPoint:.center,endPoint:.bottom)
            HStack(alignment:.bottom,spacing:18) {
                VStack(alignment:.leading,spacing:10) {
                    HStack(spacing:8) {KovaAvatar(name:video.displayName,size:35);Text("@"+video.handle).font(.system(size:15,weight:.bold));if video.isVerified == true {Image(systemName:"checkmark.seal.fill").foregroundStyle(KovaTheme.aqua)}}
                    Text(video.caption).font(.system(size:14,weight:.medium)).lineLimit(3).fixedSize(horizontal:false,vertical:true)
                    Label(video.musicTitle ?? "Original audio",systemImage:"music.note").font(.caption).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                }.frame(maxWidth:.infinity,alignment:.leading)
                VideoActions(video:video,like:like,bookmark:bookmark,comment:comment,report:report,follow:follow)
            }.padding(.horizontal,15).padding(.bottom,24)
        }.clipped()
    }
    private var demoBackground:some View {
        GeometryReader{geo in
            ZStack {
                LinearGradient(colors:KovaTheme.videoGradients[demoIndex % KovaTheme.videoGradients.count],startPoint:.topLeading,endPoint:.bottomTrailing)
                Circle().stroke(KovaTheme.lavender.opacity(0.22),lineWidth:42).frame(width:geo.size.width*0.8).offset(x:100,y:-130)
                Circle().stroke(KovaTheme.aqua.opacity(0.17),lineWidth:24).frame(width:geo.size.width*0.9).offset(x:-145,y:150)
                VStack(spacing:18) {
                    Image(systemName:"play.circle.fill").font(.system(size:68)).foregroundStyle(.white.opacity(0.86))
                    Text(["CREATE.","DISCOVER.","CONNECT."][demoIndex % 3])
                        .font(.system(size:44,weight:.black,design:.rounded)).tracking(-2)
                    Text("THE KOVA PREVIEW").font(.caption).tracking(3).foregroundStyle(.white.opacity(0.7))
                }.offset(y:-50)
            }.frame(maxWidth:.infinity,maxHeight:.infinity)
        }
    }
}
