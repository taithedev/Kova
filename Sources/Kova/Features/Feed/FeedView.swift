import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var model = FeedModel()
    @SceneStorage("kova.feed.activeVideo") private var activeID: String?
    @SceneStorage("kova.feed.mode") private var savedMode = "for-you"
    @State private var commentsVideo: KovaVideo?
    @State private var reportVideo: KovaVideo?
    @State private var needsSignIn = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                KovaTheme.background.ignoresSafeArea()
                feedContent(size: geo.size)
                feedSwitcher
                if session.isPreviewing {
                    VStack {
                        Spacer()
                        Text("BROWSING AS A GUEST")
                            .font(.caption2.bold())
                            .padding(9)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .task(id: session.user?.id) {
            model.mode = savedMode
            await model.load(api: session.api, preview: session.isPreviewing)
        }
        .sheet(item: $commentsVideo) { CommentsSheet(video: $0) }
        .sheet(item: $reportVideo) {
            ReportSheet(targetType: "video", targetID: $0.id)
        }
        .alert("Sign in to interact", isPresented: $needsSignIn) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Create a 13+ Kova account to like, repost, follow or comment.")
        }
        .alert("Kova", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func feedContent(size: CGSize) -> some View {
        if model.videos.isEmpty && model.isLoading {
            LoadingPanel(label: "Opening Kova")
        } else if model.videos.isEmpty {
            VStack(spacing: 16) {
                EmptyState(icon: "play.square.stack",
                           title: "No videos in your feed",
                           detail: "Explore newly published videos from Kova creators.")
                Button("Refresh feed") { Task { await reload() } }
                    .font(.subheadline.bold())
                    .foregroundStyle(KovaTheme.accent)
            }
        } else {
            videoScroller(size: size)
        }
    }

    private func videoScroller(size: CGSize) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(model.videos.enumerated()), id: \.element.id) { index, video in
                    videoPage(video, index: index, size: size)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollBounceBehavior(.basedOnSize)
        .scrollPosition(id: $activeID)
        .sensoryFeedback(.selection, trigger: activeID)
        .refreshable { await reload() }
        .onAppear {
            if activeID == nil { activeID = model.videos.first?.id }
        }
        .onChange(of: model.videos.count) { _, _ in
            if activeID == nil { activeID = model.videos.first?.id }
        }
    }

    private func videoPage(_ video: KovaVideo, index: Int, size: CGSize) -> some View {
        VideoCard(
            video: video,
            demoIndex: index,
            isActive: activeID == video.id,
            like: { signedIn { await model.like(video.id, api: session.api) } },
            bookmark: { signedIn { await model.bookmark(video.id, api: session.api) } },
            comment: {
                if session.user != nil { commentsVideo = video }
                else { needsSignIn = true }
            },
            report: {
                if session.user != nil { reportVideo = video }
                else { needsSignIn = true }
            },
            follow: { signedIn { await follow(video.handle) } },
            repost: { signedIn { await model.repost(video.id, api: session.api) } },
            notInterested: {
                signedIn {
                    await model.notInterested(video.id, api: session.api)
                    activeID = model.videos.first?.id
                }
            }
        )
        .frame(width: size.width, height: size.height)
        .id(video.id)
        .onAppear {
            if index >= model.videos.count - 2 {
                Task {
                    await model.loadMore(api: session.api, preview: session.isPreviewing)
                }
            }
        }
    }

    private var feedSwitcher: some View {
        HStack(spacing: 24) {
            Button("Following") { changeMode("following") }
                .foregroundStyle(model.mode == "following" ? .white : KovaTheme.muted)
            Button("For You") { changeMode("for-you") }
                .foregroundStyle(model.mode == "for-you" ? .white : KovaTheme.muted)
        }
        .font(.system(size: 16, weight: .bold))
        .padding(12)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 10)
    }

    private func reload() async {
        activeID = nil
        await model.load(api: session.api, preview: session.isPreviewing)
    }

    private func changeMode(_ mode: String) {
        if mode == "following" && session.user == nil {
            needsSignIn = true
            return
        }
        model.mode = mode
        savedMode = mode
        activeID = nil
        Task { await model.load(api: session.api, preview: session.isPreviewing) }
    }

    private func follow(_ handle: String) async {
        do {
            let result: FollowStatus = try await session.api.request(
                "/api/users/\(handle)/follow", method: "POST")
            model.errorMessage = result.status == "pending" ?
                "Follow request sent." : "Now following @\(handle)."
        } catch { model.errorMessage = error.localizedDescription }
    }

    private func signedIn(_ operation: @escaping @MainActor () async -> Void) {
        guard session.user != nil else { needsSignIn = true; return }
        Task { await operation() }
    }
}
