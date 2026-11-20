import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("kova.muteVideos") private var muteVideos = true

    var body: some View {
        List {
            Section("ACCOUNT") {
                NavigationLink { AccountCenterView() } label: {
                    Label("Account center", systemImage: "person.crop.circle.badge.checkmark")
                }
                NavigationLink { EditProfileView() } label: {
                    Label("Edit profile", systemImage: "person.text.rectangle")
                }
                NavigationLink { NotificationsView() } label: {
                    Label("Notifications", systemImage: "bell")
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
            Section("VIDEO PREFERENCES") {
                Toggle(isOn: $muteVideos) {
                    Label("Start videos muted", systemImage: "speaker.slash")
                }
                .tint(.white)
                Label("Videos always keep their original colors", systemImage: "play.rectangle")
                    .foregroundStyle(KovaTheme.muted)
            }
            Section("SAFETY") {
                LabeledContent("Direct messages", value: "Disabled")
                if let user = session.user {
                    LabeledContent("Profile", value: user.isPrivate ? "Private" : "Public")
                }
                Text("Kova accounts are 13+. Use report and block tools whenever needed.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("APP") {
                LabeledContent("Version", value: "0.3.0")
                Text("Kova connects automatically. No server configuration required.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section {
                Button("Sign out", role: .destructive) {
                    Task { await session.signOut() }
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
    }
}
