import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EditProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var displayName = ""
    @State private var bio = ""
    @State private var pronouns = ""
    @State private var avatarPreset = "mono"
    @State private var avatarURL = ""
    @State private var bannerStyle = "ink"
    @State private var isPrivate = true
    @State private var resetBanner = false
    @State private var showPublicWarning = false
    @State private var saving = false
    @State private var message: String?
    @State private var avatarSelection: PhotosPickerItem?
    @State private var bannerSelection: PhotosPickerItem?
    @State private var importAnimatedBanner = false
    @State private var uploadingMedia = false
    @State private var uploadedMedia: [ProfileMediaItem] = []

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
                PhotosPicker(selection: $avatarSelection, matching: .images) {
                    Label("Upload a profile photo", systemImage: "photo.badge.plus")
                }
                .disabled(uploadingMedia)
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
                            resetBanner = true
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
            Section("CUSTOM BANNERS") {
                PhotosPicker(selection: $bannerSelection, matching: .images) {
                    Label("Upload a banner image", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(uploadingMedia)
                Button {
                    importAnimatedBanner = true
                } label: {
                    Label("Upload animated GIF banner", systemImage: "play.rectangle")
                }
                .disabled(uploadingMedia || (session.user?.followersCount ?? 0) <= 500)
                Text((session.user?.followersCount ?? 0) > 500 ?
                     "Animated GIF banners unlocked. Maximum 15 MB." :
                     "Animated GIF banners unlock above 500 real, accepted followers.")
                    .font(.footnote)
                    .foregroundStyle(KovaTheme.muted)
                Text("Uploaded photos and GIFs appear on your profile after staff review.")
                    .font(.footnote)
                    .foregroundStyle(KovaTheme.muted)
                if uploadingMedia {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Uploading to Kova…").font(.footnote)
                    }
                }
                ForEach(uploadedMedia.prefix(5)) { media in
                    LabeledContent(media.kind.capitalized, value: media.status.capitalized)
                        .font(.footnote)
                }
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
        .task { await refreshUser(); await loadMedia() }
        .onChange(of: avatarSelection) { _, selection in
            if let selection { Task { await uploadPhoto(selection, kind: "avatar") } }
        }
        .onChange(of: bannerSelection) { _, selection in
            if let selection { Task { await uploadPhoto(selection, kind: "banner") } }
        }
        .fileImporter(isPresented: $importAnimatedBanner, allowedContentTypes: [.gif]) { picked in
            do {
                let url = try picked.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let bytes = try Data(contentsOf: url)
                Task { await upload(bytes, kind: "banner", mime: "image/gif") }
            } catch { message = error.localizedDescription }
        }
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
        resetBanner = false
        isPrivate = user.isPrivate
        if let url = user.avatarUrl, url.hasPrefix("kova-avatar:") {
            avatarPreset = String(url.dropFirst("kova-avatar:".count))
        } else {
            avatarPreset = "mono"
            avatarURL = user.avatarUrl ?? ""
        }
    }

    private func refreshUser() async {
        if let fresh: KovaUser = try? await session.api.request("/api/auth/me") {
            session.updateUser(fresh)
            loadDraft()
        }
    }

    private func loadMedia() async {
        do {
            let page: ProfileMediaPage = try await session.api.request("/api/profile/media/mine")
            uploadedMedia = page.items
        } catch {
            // Existing preset avatar and banner editing remains available.
        }
    }

    private func uploadPhoto(_ selection: PhotosPickerItem, kind: String) async {
        guard !uploadingMedia else { return }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw APIError.server("Could not read that photo.")
            }
            let jpeg = try ProfileMediaService.jpeg(from: data)
            await upload(jpeg, kind: kind, mime: "image/jpeg")
        } catch { message = error.localizedDescription }
    }

    private func upload(_ data: Data, kind: String, mime: String) async {
        guard !uploadingMedia else { return }
        uploadingMedia = true
        message = nil
        defer { uploadingMedia = false }
        do {
            let result = try await ProfileMediaService.upload(data, kind: kind, mime: mime, api: session.api)
            message = result.message
            await loadMedia()
        } catch { message = error.localizedDescription }
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
                isPrivate: isPrivate, resetBanner: resetBanner
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
    let resetBanner: Bool
}
