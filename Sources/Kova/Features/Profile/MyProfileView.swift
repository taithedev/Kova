import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var drawer: KovaNavigationState
    @State private var ownVideos: [KovaVideo] = []
    @State private var repostedVideos: [KovaVideo] = []
    @State private var selectedCategory = "videos"
    private var displayedVideos: [KovaVideo] {
        selectedCategory == "videos" ? ownVideos : repostedVideos
    }
    @State private var selectedVideo: KovaVideo?
    @State private var errorMessage: String?
    @State private var deletingID: String?
    private let columns = [GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = session.user {
                    VStack(spacing: 19) {
                        KovaProfileHeader(profile: user, ownProfile: true)
                        HStack(spacing: 10) {
                            NavigationLink { EditProfileView() } label: {
                                Label("Edit profile", systemImage: "pencil")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .kovaGlass(radius: 13)
                            }
                            NavigationLink { AccountCenterView() } label: {
                                Label("Account", systemImage: "person.text.rectangle")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 42)
                                    .kovaGlass(radius: 13)
                            }
                        }
                        .foregroundStyle(KovaTheme.foreground)
                        .padding(.horizontal, 20)
                        Picker("Profile videos", selection: $selectedCategory) {
                            Label("Videos", systemImage: "play.rectangle").tag("videos")
                            Label("Reposts", systemImage: "arrow.2.squarepath").tag("reposts")
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        HStack(spacing: 9) {
                            Image(systemName: selectedCategory == "videos" ?
                                  "play.rectangle.on.rectangle" : "arrow.2.squarepath")
                            Text(selectedCategory == "videos" ? "VIDEOS" : "REPOSTS").font(.system(size: 13, weight: .bold, design: .monospaced))
                                .tracking(1.6)
                            Spacer()
                            Text("\(displayedVideos.count)").font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                        .padding(.horizontal, 21)
                        .padding(.top, 7)
                        if displayedVideos.isEmpty {
                            EmptyState(icon: "video", title: "No videos yet",
                                       detail: selectedCategory == "videos" ?
                                       "Your uploads will appear here, including private posts." :
                                       "Repost a public video to show it on your profile.")
                                .frame(height: 210)
                        } else {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(Array(displayedVideos.enumerated()), id: \.element.id) { index, video in
                                    Button {
                                        if video.status == "approved" {
                                            selectedVideo = video
                                        } else {
                                            errorMessage = "This video was removed or is unavailable."
                                        }
                                    } label: {
                                        KovaProfileVideoTile(caption: video.caption,
                                            thumbnail: video.thumbnailUrl, index: index, status: video.status)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        if selectedCategory == "videos" {
                                            Button("Delete video", systemImage: "trash", role: .destructive) {
                                                deletingID = video.id
                                            }
                                        } else {
                                            Button("Undo repost", systemImage: "arrow.uturn.backward") {
                                                Task { await removeRepost(video.id) }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                } else {
                    EmptyState(icon: "person.crop.circle", title: "Your space awaits",
                               detail: "Sign in to customize your profile, follow people and create videos.")
                    GradientButton("Leave preview") { session.exitPreview() }
                        .padding(.horizontal, 25)
                }
            }
            .background(KovaTheme.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            drawer.isOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(KovaTheme.foreground)
                    }
                    .accessibilityLabel("Open Kova navigation")
                }
            }
            .sheet(item: $selectedVideo) { video in
                KovaProfileVideoViewer(
                    videos: displayedVideos.filter { $0.status == "approved" },
                    initialVideoID: video.id
                )
                .environmentObject(session)
            }
            .task { await load() }
            .refreshable { await load() }
            .confirmationDialog("Delete this video?", isPresented: Binding(
                get: { deletingID != nil }, set: { if !$0 { deletingID = nil } }
            )) {
                Button("Delete video", role: .destructive) {
                    if let id = deletingID { Task { await removeVideo(id) } }
                }
            } message: { Text("You cannot undo this action.") }
        }
    }

    private func load() async {
        guard session.user != nil else { return }
        if let fresh: KovaUser = try? await session.api.request("/api/auth/me") {
            session.updateUser(fresh)
        }
        do {
            let page: OwnVideoPage = try await session.api.request("/api/videos/mine")
            ownVideos = page.items
            if let handle = session.user?.handle,
               let repostPage: OwnVideoPage = try? await session.api.request(
                   "/api/users/\(handle)/reposts") {
                repostedVideos = repostPage.items
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private func removeRepost(_ id: String) async {
        do {
            let _: RepostResult = try await session.api.request(
                "/api/videos/\(id)/repost", method: "DELETE")
            repostedVideos.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }

    private func removeVideo(_ id: String) async {
        defer { deletingID = nil }
        do {
            let _: DeletedKovaVideo = try await session.api.request("/api/videos/\(id)", method: "DELETE")
            ownVideos.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }
}
private struct DeletedKovaVideo: Decodable { let deleted: Bool }
struct OwnVideoPage: Decodable { let items: [KovaVideo] }
