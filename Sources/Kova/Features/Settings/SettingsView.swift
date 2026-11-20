import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("kova.muteVideos") private var muteVideos = true
    @AppStorage("kova.appearance") private var appearance = "dark"
    @AppStorage("kova.accent") private var accent = "classic"

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
                Text("Choose your preferred appearance. Profile banners, videos and verified badges retain their original colors.")
                    .font(.footnote)
                    .foregroundStyle(KovaTheme.muted)
            }
            Section("ACCENT COLOR") {
                HStack(spacing: 10) {
                    ForEach(KovaAccent.options, id: \.key) { option in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) { accent = option.key }
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 31, height: 31)
                                .overlay {
                                    if accent == option.key {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundStyle(option.key == "classic" ? KovaTheme.inverted : .white)
                                    }
                                }
                                .padding(3)
                                .overlay(Circle().stroke(accent == option.key ? KovaTheme.foreground : KovaTheme.border,
                                                         lineWidth: accent == option.key ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use " + option.name + " accent")
                    }
                }
                .padding(.vertical, 6)
                LabeledContent("Selected", value: KovaAccent.options.first(where: { $0.key == accent })?.name ?? "Classic")
                Text("Accent colors affect selection and controls. Videos and profile media keep their original colors.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
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
                NavigationLink { KovaFeedPreferencesView() } label: {
                    Label("For You controls", systemImage: "slider.horizontal.3")
                }
                NavigationLink { NotificationsView() } label: {
                    Label("Notifications", systemImage: "bell")
                }
                if session.hasVerifiedSession, let role = session.user?.role {
                    if ["owner", "admin", "moderator"].contains(role) {
                        NavigationLink { ModerationView() } label: {
                            Label("Live video moderation", systemImage: "checkmark.shield")
                        }
                        NavigationLink { KovaAccountSafetyView() } label: {
                            Label("Account age & messaging restrictions", systemImage: "lock.shield")
                        }
                        NavigationLink { StaffSupportView() } label: {
                            Label("Support ticket queue", systemImage: "bubble.left.and.bubble.right")
                        }
                        NavigationLink { StaffMediaReviewView() } label: {
                            Label("Profile media takedowns", systemImage: "photo.badge.checkmark")
                        }
                        if role == "owner" || role == "admin" {
                            NavigationLink { KovaVerificationCenterView() } label: {
                                Label("Verify users", systemImage: "checkmark.seal.fill")
                            }
                        }
                        NavigationLink { StaffDashboardView() } label: {
                            Label("Staff dashboard", systemImage: "shield.lefthalf.filled")
                        }
                    }
                    if role == "owner" {
                        NavigationLink { OwnerConsoleView() } label: {
                            Label("Owner console", systemImage: "chart.pie.xaxis")
                        }
                    }
                    if role == "owner" || role == "developer" {
                        NavigationLink { DeveloperStudioView() } label: {
                            Label("Creator studio", systemImage: "chart.bar.xaxis")
                        }
                    }
                }
            }
            Section("HELP & CONTACT") {
                NavigationLink { SupportCenterView() } label: {
                    Label("Support tickets", systemImage: "lifepreserver")
                }
                NavigationLink { PrivateContactsView() } label: {
                    Label("Optional email and phone", systemImage: "envelope.badge.shield.half.filled")
                }
            }
            Section("PLAYBACK") {
                Toggle("Start videos muted", isOn: $muteVideos).tint(KovaTheme.foreground)
            }
            Section("SAFETY") {
                NavigationLink { KovaMessagesSettingsView() } label: {
                    Label("Private messaging preferences", systemImage: "bubble.left.and.bubble.right")
                }
                LabeledContent("Direct messages", value: session.user?.ageRestricted == true ? "Restricted by staff" :
                    (session.user?.allowMessages == true ? "Mutual follows only" : "Off"))
                LabeledContent("Account", value: session.user?.isPrivate == true ? "Private" : "Public")
                Text("New accounts start private. Public videos go live immediately when your account is public. Report unsafe content.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("ABOUT") {
                LabeledContent("Version", value: "0.8.0")
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
