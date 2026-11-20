import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var session: SessionStore
    let handle: String
    @State private var result: ProfileResponse?
    @State private var message: String?
    @State private var isFollowing = false
    @State private var requested = false
    @State private var report = false
    @State private var selectedVideo: KovaVideo?
    @State private var showMessages = false
    @State private var confirmBlock = false
    @State private var didBlock = false
    private let columns = [GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4)]

    var body: some View {
        ScrollView {
            if didBlock {
                EmptyState(icon: "hand.raised", title: "Account blocked",
                           detail: "You will no longer see this account or its videos.")
                    .frame(height: 350)
            } else if let result {
                VStack(spacing: 19) {
                    KovaProfileHeader(profile: result.profile)
                    HStack(spacing: 10) {
                        if session.user?.handle != handle {
                            Button {
                                if !requested { Task { await follow() } }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: requested ? "clock" : (isFollowing ? "checkmark" : "person.badge.plus.fill"))
                                        .font(.system(size: 19, weight: .semibold))
                                    Text(requested ? "Requested" : (isFollowing ? "Following" : "Follow"))
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(KovaTheme.accent, in: RoundedRectangle(cornerRadius: 17))
                            }
                            .buttonStyle(.plain)
                            .disabled(requested)
                            Button {
                                showMessages = true
                            } label: {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 19, weight: .semibold))
                                    .frame(width: 56, height: 56)
                                    .kovaGlass(radius: 15)
                            }
                            .foregroundStyle(KovaTheme.foreground)
                            .accessibilityLabel("Message @" + handle)
                        }
                        Button {
                            report = true
                        } label: {
                            Image(systemName: "flag")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 49, height: 51)
                                .kovaGlass(radius: 15)
                        }
                        .foregroundStyle(KovaTheme.foreground)
                        .accessibilityLabel("Report user")
                    }
                    .padding(.horizontal, 20)
                    if result.profile.isPrivate && !isFollowing && session.user?.id != result.profile.id {
                        EmptyState(icon: "lock.shield", title: "This account is private",
                                   detail: "Follow requests need approval before you can see private posts.")
                            .frame(height: 190)
                    } else {
                        HStack {
                            Image(systemName: "square.grid.3x3.fill")
                            Text("VIDEOS").font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1.4)
                            Spacer()
                            Text("\(result.videos.count)")
                                .font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                        .padding(.horizontal, 21)
                        if result.videos.isEmpty {
                            EmptyState(icon: "play.square", title: "No videos yet",
                                       detail: "Published videos from this creator will appear here.")
                                .frame(height: 180)
                        } else {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(Array(result.videos.enumerated()), id: \.element.id) { index, video in
                                    Button {
                                        selectedVideo = video
                                    } label: {
                                        KovaProfileVideoTile(caption: video.caption,
                                                             thumbnail: video.thumbnailUrl, index: index)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Play " + video.caption)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                    if let message {
                        Text(message).font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.bottom, 25)
            } else if let message {
                EmptyState(icon: "person.crop.circle.badge.questionmark", title: "Couldn't open profile",
                           detail: message).frame(height: 280)
            } else {
                LoadingPanel()
            }
        }
        .background(KovaTheme.background)
        .navigationTitle("@" + handle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if session.user != nil && session.user?.handle != handle {
                    Menu {
                        Button("Report account", systemImage: "flag") { report = true }
                        Button("Block account", systemImage: "hand.raised", role: .destructive) {
                            confirmBlock = true
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundStyle(KovaTheme.foreground)
                    }
                }
            }
        }
        .sheet(item: $selectedVideo) { selected in
            KovaProfileVideoViewer(videos: result?.videos ?? [], initialVideoID: selected.id)
                .environmentObject(session)
        }
        .sheet(isPresented: $showMessages) {
            NavigationStack {
                KovaConversationView(handle: handle)
            }
        }
        .sheet(isPresented: $report) {
            if let id = result?.profile.id { ReportSheet(targetType: "user", targetID: id) }
        }
        .confirmationDialog("Block this account?", isPresented: $confirmBlock) {
            Button("Block account", role: .destructive) { Task { await block() } }
        } message: { Text("Their posts and profile will no longer appear for you.") }
    }

    private func load() async {
        do {
            result = try await session.api.request("/api/users/\(handle)")
            isFollowing = result?.profile.isFollowing ?? false
        } catch { message = error.localizedDescription }
    }
    private func follow() async {
        guard session.user != nil else { message = "Sign in to follow people."; return }
        do {
            let response: FollowResult = try await session.api.request(
                "/api/users/\(handle)/follow", method: isFollowing ? "DELETE" : "POST")
            isFollowing = response.status == "accepted"
            if response.status == "pending" {
                requested = true
                message = "Follow request sent."
            } else if response.status == nil {
                message = "Unfollowed."
            }
        } catch { message = error.localizedDescription }
    }
    private func block() async {
        guard session.user != nil else { return }
        do {
            let body = try session.api.encode(BlockProfilePayload(handle: handle))
            let _: BlockProfileResponse = try await session.api.request("/api/users/me/block", method: "POST", json: body)
            didBlock = true
        } catch { message = error.localizedDescription }
    }
}
private struct FollowResult: Decodable { let status: String?; let following: Bool? }
private struct BlockProfilePayload: Encodable { let handle: String }
private struct BlockProfileResponse: Decodable { let blocked: Bool }
