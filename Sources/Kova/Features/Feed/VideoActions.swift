import SwiftUI
struct VideoActions:View {
    let video:KovaVideo
    let like:()->Void
    let bookmark:()->Void
    let comment:()->Void
    let report:()->Void
    let follow:()->Void
    var body:some View {
        VStack(spacing:22) {
            Button(action:follow){ZStack(alignment:.bottom){KovaAvatar(name:video.handle,size:50);Image(systemName:"plus.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white,KovaTheme.lavender).offset(y:10)}}
            actionButton("heart.fill",count:video.likesCount,color:video.liked ? .pink:.white,action:like)
            actionButton("bubble.right.fill",count:video.commentsCount,color:.white,action:comment)
            actionButton(video.bookmarked ? "bookmark.fill":"bookmark",count:nil,color:video.bookmarked ? KovaTheme.lavender : .white,action:bookmark)
            if video.isDemo {Image(systemName:"square.and.arrow.up").font(.system(size:28)).foregroundStyle(.white.opacity(0.6))} else {
                ShareLink(item:URL(string:video.videoUrl) ?? URL(string:"https://example.com")!){Image(systemName:"square.and.arrow.up").font(.system(size:27)).foregroundStyle(.white)}
            }
            Button(action:report){Image(systemName:"ellipsis").font(.system(size:25,weight:.bold)).foregroundStyle(.white)}
        }.buttonStyle(.plain).frame(width:58)
    }
    private func actionButton(_ icon:String,count:Int?,color:Color,action:@escaping ()->Void)->some View {
        Button(action:action){VStack(spacing:5){Image(systemName:icon).font(.system(size:29));if let count {Text(count.formatted(.number.notation(.compactName))).font(.system(size:12,weight:.bold))}}.foregroundStyle(color)}
    }
}
