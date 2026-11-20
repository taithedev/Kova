import SwiftUI
struct VideoActions: View {
    let video: KovaVideo
    let like: () -> Void
    let bookmark: () -> Void
    let comment: () -> Void
    let report: () -> Void
    let follow: () -> Void
    let repost: () -> Void
    let notInterested: () -> Void
    private var shareURL: URL {
        URL(string: "/watch/\(video.id)", relativeTo: AppConfig.apiBaseURL)!.absoluteURL
    }
    var body: some View {
        VStack(spacing: 23) {
            Button(action: follow) {
                KovaAvatar(name: video.handle, size: 50, url: video.avatarUrl)
                    .overlay(alignment: .bottom) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .black)
                            .offset(y: 10)
                    }
            }
            actionButton(video.liked ? "heart.fill" : "heart", count: video.likesCount, action: like)
            actionButton("bubble.right", count: video.commentsCount, action: comment)
            actionButton(video.bookmarked ? "bookmark.fill" : "bookmark", count: nil, action: bookmark)
            Button(action: repost) {
                VStack(spacing: 5) {
                    Image(systemName: video.reposted ? "arrow.2.squarepath" : "arrow.2.squarepath")
                        .font(.system(size: 27))
                        .foregroundStyle(video.reposted ? KovaTheme.accent : .white)
                    Text(video.repostsCount.formatted(.number.notation(.compactName)))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel(video.reposted ? "Undo repost" : "Repost this video")
            if !video.isDemo && AppConfig.isConfigured {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 27)).foregroundStyle(.white)
                }.accessibilityLabel("Share video")
            }
            Menu {
                Button("Not interested", systemImage: "eye.slash", action: notInterested)
                Button("Report video", systemImage: "flag", action: report)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Video options")
        }
        .buttonStyle(.plain)
        .frame(width: 58)
    }
    private func actionButton(_ symbol: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 29))
                if let count {
                    Text(count.formatted(.number.notation(.compactName)))
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(.white)
        }
        .accessibilityLabel(symbol)
    }
}
