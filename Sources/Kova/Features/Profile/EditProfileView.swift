import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var displayName = ""
    @State private var bio = ""
    @State private var pronouns = ""
    @State private var avatarPreset = "mono"
    @State private var avatarURL = ""
    @State private var bannerStyle = "ink"
    @State private var isPrivate = true
    @State private var showPublicWarning = false
    @State private var saving = false
    @State private var message: String?

    private let bannerOptions = ["ink", "glacier", "orchid", "coral", "mint", "sunset"]
    private let avatarOptions = ["mono", "violet", "ocean", "sunset", "moss", "rose"]

    var body: some View {
        Form {
            Section("YOUR PROFILE") {
                HStack(spacing: 14) {
                    KovaAvatar(name: displayName.isEmpty ? "Kova" : displayName,
                               size: 67, url: avatarURL.isEmpty ? "kova-avatar:" + avatarPreset : avatarURL)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(displayName.isEmpty ? "Your profile" : displayName).font(.headline)
                        Text("Choose an avatar and a banner.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.vertical, 7)
                TextField("Display name", text: $displayName)
                    .textContentType(.nickname)
                TextField("Pronouns (optional)", text: $pronouns)
                    .textContentType(.nickname)
                TextField("Your bio", text: $bio, axis: .vertical)
                    .lineLimit(2...5)
                Text("\(bio.count)/160 characters")
                    .font(.caption2).foregroundStyle(KovaTheme.muted)
            }
            Section("PROFILE PICTURE") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(avatarOptions, id: \.self) { preset in
                            Button {
                                avatarPreset = preset
                                avatarURL = ""
                            } label: {
                                KovaAvatar(name: displayName.isEmpty ? "K" : displayName,
                                           size: 56, url: "kova-avatar:" + preset)
                                    .overlay(Circle().stroke(avatarPreset == preset && avatarURL.isEmpty ?
                                                             KovaTheme.foreground : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose \(preset) avatar")
                        }
                    }
                    .padding(.vertical, 9)
                }
                DisclosureGroup("Use an HTTPS profile photo link") {
                    TextField("https://example.com/photo.jpg", text: $avatarURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("You can use your own hosted picture. Avoid using someone else's photo without permission.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            Section("BANNER COLOR") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(bannerOptions, id: \.self) { option in
                        Button {
                            bannerStyle = option
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(KovaTheme.banner(option))
                                    .frame(height: 62)
                                    .overlay(alignment: .topTrailing) {
                                        if bannerStyle == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .padding(6)
                                        }
                                    }
                                    .overlay(RoundedRectangle(cornerRadius: 11)
                                        .stroke(bannerStyle == option ? KovaTheme.foreground : .clear, lineWidth: 2))
                                Text(option.capitalized)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(KovaTheme.foreground)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 7)
            }
            Section("PRIVACY") {
                Toggle("Private account", isOn: $isPrivate)
                    .tint(KovaTheme.foreground)
                    .onChange(of: isPrivate) { old, new in
                        if old && !new { showPublicWarning = true }
                    }
                Text("Every new Kova account starts private. You can change it here. A public profile can be seen by anyone; videos still need approval before appearing in feeds.")
                    .font(.footnote)
                    .foregroundStyle(KovaTheme.muted)
            }
            Section {
                Button(saving ? "Saving..." : "Save profile") {
                    Task { await save() }
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(saving || displayName.trimmingCharacters(in: .whitespaces).isEmpty || bio.count > 160 || pronouns.count > 32)
            }
            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .navigationTitle("Edit profile")
        .onAppear { loadDraft() }
        .confirmationDialog("Make your profile public?", isPresented: $showPublicWarning) {
            Button("Keep my profile public") { isPrivate = false }
            Button("Keep private", role: .cancel) { isPrivate = true }
        } message: {
            Text("Anyone could see your public profile, posts you share publicly, display name, and bio.")
        }
    }

    private func loadDraft() {
        guard let user = session.user else { return }
        displayName = user.displayName
        bio = user.bio ?? ""
        pronouns = user.pronouns ?? ""
        bannerStyle = user.bannerStyle ?? "ink"
        isPrivate = user.isPrivate
        if let url = user.avatarUrl, url.hasPrefix("kova-avatar:") {
            avatarPreset = String(url.dropFirst("kova-avatar:".count))
        } else {
            avatarPreset = "mono"
            avatarURL = user.avatarUrl ?? ""
        }
    }

    private func save() async {
        guard !saving else { return }
        saving = true
        message = nil
        defer { saving = false }
        do {
            let avatar = avatarURL.trimmingCharacters(in: .whitespacesAndNewlines)
            let payload = try session.api.encode(EditProfilePayload(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio, pronouns: pronouns, bannerStyle: bannerStyle,
                avatarUrl: avatar.isEmpty ? "kova-avatar:" + avatarPreset : avatar,
                isPrivate: isPrivate
            ))
            let updated: KovaUser = try await session.api.request("/api/users/me", method: "PATCH", json: payload)
            session.updateUser(updated)
            message = "Your profile was updated."
        } catch {
            message = error.localizedDescription
        }
    }
}
private struct EditProfilePayload: Encodable {
    let displayName: String
    let bio: String
    let pronouns: String
    let bannerStyle: String
    let avatarUrl: String
    let isPrivate: Bool
}
