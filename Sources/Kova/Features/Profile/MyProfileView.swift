import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var ownVideos: [OwnVideo] = []
    @State private var errorMessage: String?
    @State private var deletingID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let user = session.user {
                    VStack(spacing: 16) {
                        KovaAvatar(name: user.displayName, size: 95).padding(.top, 23)
                        Text(user.displayName).font(.kovaHeadline)
                        Text("@" + user.handle).foregroundStyle(KovaTheme.muted)
                        HStack(spacing: 32) {
                            stat("Followers", value: user.followersCount ?? 0)
                            stat("Following", value: user.followingCount ?? 0)
                        }
                        .padding(.top, 7)
                        HStack(spacing: 12) {
                            NavigationLink("Edit profile") { EditProfileView() }
                            NavigationLink("Settings") { SettingsView() }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        NavigationLink { AccountCenterView() } label: {
                            Label("Account center", systemImage: "lock.shield")
                        }
                        .foregroundStyle(.white)
                        .padding(.top, 3)
                        Text(user.bio?.isEmpty == false ? (user.bio ?? "") : "Make this space yours.")
                            .font(.footnote)
                            .foregroundStyle(KovaTheme.muted)
                        Divider().overlay(KovaTheme.border)
                        SectionHeading(title: "My videos", subtitle: "Uploads are reviewed before becoming public")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if ownVideos.isEmpty {
                            EmptyState(icon: "film.stack", title: "Nothing posted yet", detail: "Create your first Kova video.")
                                .frame(height: 250)
                        } else {
                            ForEach(ownVideos) { video in
                                HStack(spacing: 12) {
                                    Image(systemName: "film").font(.system(size: 22))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(video.caption.isEmpty ? "Untitled video" : video.caption)
                                            .lineLimit(2).font(.system(size: 14, weight: .semibold))
                                        Text(video.status.capitalized + " · " + video.visibility.capitalized)
                                            .font(.caption2).foregroundStyle(KovaTheme.muted)
                                    }
                                    Spacer()
                                    Menu {
                                        Button("Delete video", systemImage: "trash", role: .destructive) {
                                            deletingID = video.id
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(15)
                                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    EmptyState(icon: "person.crop.circle", title: "Your space awaits",
                               detail: "Sign in to create and save videos.")
                    GradientButton("Leave preview") { session.exitPreview() }
                        .padding(.horizontal, 25)
                }
            }
            .background(KovaTheme.background)
            .navigationTitle("Profile")
            .task { await load() }
            .refreshable { await load() }
            .confirmationDialog("Delete this video?", isPresented: Binding(
                get: { deletingID != nil },
                set: { if !$0 { deletingID = nil } }
            )) {
                Button("Delete video", role: .destructive) {
                    if let id = deletingID { Task { await removeVideo(id) } }
                }
            } message: {
                Text("This removes the video from your profile and Kova's feed.")
            }
        }
    }
    private func stat(_ title: String, value: Int) -> some View {
        VStack(spacing: 5) {
            Text(value.formatted()).font(.title3).bold()
            Text(title).font(.caption).foregroundStyle(KovaTheme.muted)
        }
    }
    private func load() async {
        guard session.user != nil else { return }
        do {
            let response: OwnVideoPage = try await session.api.request("/api/videos/mine")
            ownVideos = response.items
        } catch { errorMessage = error.localizedDescription }
    }
    private func removeVideo(_ id: String) async {
        defer { deletingID = nil }
        do {
            let _: DeletedKovaVideo = try await session.api.request("/api/videos/\(id)", method: "DELETE")
            ownVideos.removeAll { $0.id == id }
            errorMessage = "Video deleted."
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
