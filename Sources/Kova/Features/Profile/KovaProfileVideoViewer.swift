import SwiftUI

/// Plays a creator's posts with the same controls as the Home feed.
/// Every post has its own signed playback URL and permission checks.
struct KovaProfileVideoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let videos: [KovaVideo]
    @State private var currentID: String?

    init(videos: [KovaVideo], initialVideoID: String) {
        self.videos = videos
        _currentID = State(initialValue: initialVideoID)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(videos) { video in
                            KovaProfileVideoPage(
                                video: video,
                                isActive: currentID == video.id
                            )
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                            .id(video.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $currentID)
                .sensoryFeedback(.selection, trigger: currentID)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 41, height: 41)
                        .foregroundStyle(.white)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Close video player")
                .padding(15)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct KovaProfileVideoPage: View {
    @EnvironmentObject private var session: SessionStore
    let video: KovaVideo
    let isActive: Bool
    @State private var current: KovaVideo
    @State private var commentsVideo: KovaVideo?
    @State private var showReport = false
    @State private var profile: KovaProfileDestination?
    @State private var errorMessage: String?

    init(video: KovaVideo, isActive: Bool) {
        self.video = video
        self.isActive = isActive
        _current = State(initialValue: video)
    }

    var body: some View {
        VideoCard(
            video: current,
            demoIndex: 0,
            isActive: isActive,
            like: { Task { await toggleLike() } },
            bookmark: { Task { await toggleBookmark() } },
            comment: { commentsVideo = current },
            report: { showReport = true },
            follow: { Task { await follow() } },
            openProfile: { profile = KovaProfileDestination(handle: video.handle) },
            repost: { Task { await toggleRepost() } },
            notInterested: { Task { await hideVideo() } }
        )
        .sheet(item: $commentsVideo) { CommentsSheet(video: $0) }
        .sheet(isPresented: $showReport) {
            ReportSheet(targetType: "video", targetID: video.id)
        }
        .sheet(item: $profile) { destination in
            NavigationStack { UserProfileView(handle: destination.handle) }
        }
        .alert("Kova", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func toggleLike() async {
        guard session.user != nil else { errorMessage = "Sign in to like videos."; return }
        let wasLiked = current.liked
        do {
            let _: LikeResult = try await session.api.request(
                "/api/videos/\(video.id)/like", method: wasLiked ? "DELETE" : "POST")
            current.liked = !wasLiked
            current.likesCount = max(0, current.likesCount + (wasLiked ? -1 : 1))
        } catch { errorMessage = error.localizedDescription }
    }

    private func toggleBookmark() async {
        guard session.user != nil else { errorMessage = "Sign in to save videos."; return }
        let saved = current.bookmarked
        do {
            let _: BookmarkResult = try await session.api.request(
                "/api/videos/\(video.id)/bookmark", method: saved ? "DELETE" : "POST")
            current.bookmarked = !saved
        } catch { errorMessage = error.localizedDescription }
    }

    private func toggleRepost() async {
        guard session.user != nil else { errorMessage = "Sign in to repost."; return }
        let reposted = current.reposted
        do {
            let result: RepostResult = try await session.api.request(
                "/api/videos/\(video.id)/repost", method: reposted ? "DELETE" : "POST")
            current.reposted = result.reposted
            current.repostsCount = result.repostsCount
        } catch { errorMessage = error.localizedDescription }
    }

    private func hideVideo() async {
        guard session.user != nil else { errorMessage = "Sign in to customize your feed."; return }
        do {
            let _: VideoPreferenceResult = try await session.api.request(
                "/api/videos/\(video.id)/not-interested", method: "POST")
            errorMessage = "This video won't appear in your For You feed."
        } catch { errorMessage = error.localizedDescription }
    }

    private func follow() async {
        guard let signed = session.user else { errorMessage = "Sign in to follow."; return }
        if signed.handle == video.handle { return }
        do {
            let result: FollowStatus = try await session.api.request(
                "/api/users/\(video.handle)/follow", method: "POST")
            errorMessage = result.status == "pending" ?
                "Follow request sent to @\(video.handle)." : "Following @\(video.handle)."
        } catch { errorMessage = error.localizedDescription }
    }
}
