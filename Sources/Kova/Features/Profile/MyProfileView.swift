import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var ownVideos: [OwnVideo] = []
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
                        HStack(spacing: 9) {
                            Image(systemName: "play.rectangle.on.rectangle")
                            Text("VIDEOS").font(.system(size: 13, weight: .bold, design: .monospaced))
                                .tracking(1.6)
                            Spacer()
                            Text("\(ownVideos.count)").font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                        .padding(.horizontal, 21)
                        .padding(.top, 7)
                        if ownVideos.isEmpty {
                            EmptyState(icon: "video", title: "No videos yet",
                                       detail: "Your uploads will appear here, including videos awaiting review.")
                                .frame(height: 210)
                        } else {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(Array(ownVideos.enumerated()), id: \.element.id) { index, video in
                                    Menu {
                                        Text(video.status == "pending" ? "Awaiting review" : video.status.capitalized)
                                        Button("Delete video", systemImage: "trash", role: .destructive) {
                                            deletingID = video.id
                                        }
                                    } label: {
                                        KovaProfileVideoTile(caption: video.caption, index: index, status: video.status)
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
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(KovaTheme.foreground)
                    }
                    .accessibilityLabel("Settings")
                }
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
struct OwnVideo: Decodable, Identifiable {
    let id: String
    let caption: String
    let videoUrl: String
    let status: String
    let visibility: String
    let createdAt: String
}
struct OwnVideoPage: Decodable { let items: [OwnVideo] }
