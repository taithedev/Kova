import SwiftUI
struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("kova.muteVideos") private var muteVideos = true
    var body: some View {
        List {
            Section("PREFERENCES") {
                Toggle(isOn: $muteVideos) {
                    Label("Start videos muted", systemImage: "speaker.slash")
                }
                .tint(.white)
                Label("Videos always play in their original color", systemImage: "play.rectangle")
                    .foregroundStyle(KovaTheme.muted)
            }
            Section("PRIVACY & ACCOUNT") {
                if let user = session.user {
                    LabeledContent("Age group", value: user.ageBand ?? "Unknown")
                    LabeledContent("Messages", value: "Disabled")
                }
                NavigationLink { EditProfileView() } label: {
                    Label("Edit profile and privacy", systemImage: "lock.shield")
                }
                NavigationLink { BookmarksView() } label: {
                    Label("Saved videos", systemImage: "bookmark")
                }
                NavigationLink { FollowRequestsView() } label: {
                    Label("Follow requests", systemImage: "person.2")
                }
                if session.user?.role == "admin" || session.user?.role == "moderator" {
                    NavigationLink { ModerationView() } label: {
                        Label("Moderation queue", systemImage: "checkmark.shield")
                    }
                }
            }
            Section("ABOUT") {
                LabeledContent("Version", value: "0.2.0")
                Text("No harassment, bullying, spam, or sharing someone else's personal information. Report unsafe content.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section { Button("Sign out", role: .destructive) { Task { await session.signOut() } } }
        }
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .navigationTitle("Settings")
    }
}
