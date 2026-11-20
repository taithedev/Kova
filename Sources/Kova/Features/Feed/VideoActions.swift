import SwiftUI
struct VideoActions: View {
    @EnvironmentObject private var session: SessionStore
    let video: KovaVideo
    let like: () -> Void
    let bookmark: () -> Void
    let comment: () -> Void
    let report: () -> Void
    let follow: () -> Void
    let openProfile: () -> Void
    let repost: () -> Void
    let notInterested: () -> Void
    private var shareURL: URL {
        URL(string: "/watch/\(video.id)", relativeTo: AppConfig.apiBaseURL)!.absoluteURL
    }
    var body: some View {
        VStack(spacing: 19) {
            Button(action: openProfile) {
                KovaAvatar(name: video.handle, size: 55, url: video.avatarUrl)
                    .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
            }
            .accessibilityLabel("Open @" + video.handle + " profile")
            if session.user?.handle != video.handle {
                Button(action: follow) {
                    Label("Follow", systemImage: "person.badge.plus")
                        .font(.system(size: 13, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 11)
                        .frame(minWidth: 78)
                        .background(.white, in: Capsule())
                        .foregroundStyle(.black)
                }
                .accessibilityLabel("Follow @" + video.handle)
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
        .frame(width: 86)
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
