import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("kova.muteVideos") private var muteVideos = true
    @AppStorage("kova.appearance") private var appearance = "dark"

    var body: some View {
        List {
            Section("APPEARANCE") {
                Picker("Kova style", selection: $appearance) {
                    Text("Follow iPhone").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("OLED black").tag("oled")
                }
                .pickerStyle(.menu)
                HStack(spacing: 7) {
                    appearancePreview("light", title: "Light")
                    appearancePreview("dark", title: "Dark")
                    appearancePreview("oled", title: "OLED")
                }
                .padding(.vertical, 8)
                Text("Buttons and controls stay black and white. Videos, profile banners and blue verified badges keep their original colors.")
                    .font(.footnote)
                    .foregroundStyle(KovaTheme.muted)
            }
            Section("PROFILE & ACCOUNT") {
                NavigationLink { EditProfileView() } label: {
                    Label("Edit profile", systemImage: "person.crop.circle")
                }
                NavigationLink { AccountCenterView() } label: {
                    Label("Account center", systemImage: "person.text.rectangle")
                }
                NavigationLink { BookmarksView() } label: {
                    Label("Saved videos", systemImage: "bookmark")
                }
                NavigationLink { FollowRequestsView() } label: {
                    Label("Follow requests", systemImage: "person.2")
                }
                NavigationLink { NotificationsView() } label: {
                    Label("Notifications", systemImage: "bell")
                }
                if let role = session.user?.role {
                    if ["owner", "admin", "moderator"].contains(role) {
                        NavigationLink { ModerationView() } label: {
                            Label("Moderation queue", systemImage: "checkmark.shield")
                        }
                        NavigationLink { StaffDashboardView() } label: {
                            Label("Staff dashboard", systemImage: "shield.lefthalf.filled")
                        }
                    }
                    if role == "owner" || role == "developer" {
                        NavigationLink { DeveloperStudioView() } label: {
                            Label("Creator studio", systemImage: "chart.bar.xaxis")
                        }
                    }
                }
            }
            Section("PLAYBACK") {
                Toggle("Start videos muted", isOn: $muteVideos).tint(KovaTheme.foreground)
            }
            Section("SAFETY") {
                LabeledContent("Direct messages", value: "Disabled")
                LabeledContent("Account", value: session.user?.isPrivate == true ? "Private" : "Public")
                Text("New accounts start private. Changing privacy is your choice; public profiles can be viewed by anyone.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("ABOUT") {
                LabeledContent("Version", value: "0.4.0")
                Text("Kova is made for people. No automated follows, bots, or generated-content feeds.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section {
                Button("Sign out", role: .destructive) { Task { await session.signOut() } }
            }
        }
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .navigationTitle("Settings")
    }

    private func appearancePreview(_ mode: String, title: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.25)) { appearance = mode } } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(mode == "light" ? Color.white : (mode == "dark" ? Color(white: 0.13) : .black))
                    .frame(height: 58)
                    .overlay {
                        VStack(spacing: 5) {
                            Capsule()
                                .fill(mode == "light" ? .black : .white)
                                .frame(width: 40, height: 5)
                            Capsule()
                                .fill(mode == "light" ? Color.black.opacity(0.2) : Color.white.opacity(0.35))
                                .frame(width: 57, height: 4)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(appearance == mode ? KovaTheme.foreground : KovaTheme.border, lineWidth: appearance == mode ? 2 : 1))
                Text(title)
                    .font(.system(size: 11, weight: appearance == mode ? .bold : .medium))
                    .foregroundStyle(KovaTheme.foreground)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Set \(title) appearance")
    }
}
