import SwiftUI
import PhotosUI
import AVKit

struct UploadView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var remix: KovaRemixCoordinator
    @State private var selected: PhotosPickerItem?
    @State private var selectedURL: URL?
    @State private var originalURL: URL?
    @State private var editing: KovaEditingInput?
    @State private var pendingRecorded: KovaEditingInput?
    @State private var caption = ""
    @State private var description = ""
    @State private var allowRemix = false
    @State private var musicTitle = "Original audio"
    @State private var preparingRemix = false
    @State private var sourceVideoID: String?
    @State private var remixType: String?
    @State private var remixCredit: String?
    @State private var visibility = "private"
    @State private var showCamera = false
    @State private var uploading = false
    @State private var message: String?

    private var accountID: String { session.user?.id ?? "" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    header
                    capturePanel
                    captionPanel
                    descriptionPanel
                    soundPanel
                    privacyPanel
                    remixPanel
                    publishPanel
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KovaTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCamera, onDismiss: cameraDismissed) {
                KovaRecorderView { video, preset in
                    originalURL = video
                    selectedURL = video
                    pendingRecorded = KovaEditingInput(
                        url: video, initialFilter: KovaVideoFilter(rawValue: preset) ?? .original)
                }
            }
            .sheet(item: $editing) { source in
                KovaEditorView(input: source) { output, soundCredit in
                    selectedURL = output
                    musicTitle = soundCredit
                    message = "Video edited with " + soundCredit + ". Ready to publish."
                }
            }
            .onChange(of: selected) { _, item in
                Task { await importSelection(item) }
            }
            .task { restoreDrafts() }
            .onChange(of: caption) { _, value in
                saveDraft(value, key: "video.caption")
            }
            .onChange(of: description) { _, value in
                saveDraft(value, key: "video.description")
            }
            .onChange(of: visibility) { _, value in
                saveDraft(value, key: "video.visibility")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CREATE / KOVA")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(1.7)
                .foregroundStyle(KovaTheme.muted)
            Text("Make your next video.")
                .font(.system(size: 31, weight: .heavy))
            Text("Record, add effects and share your work.")
                .font(.subheadline).foregroundStyle(KovaTheme.muted)
            if let intent = remix.intent {
                Label("Create a " + intent.kind.capitalized + " with @" + intent.sourceHandle,
                      systemImage: "rectangle.on.rectangle")
                    .font(.subheadline.bold()).foregroundStyle(KovaTheme.accent)
            }
            if let remixCredit {
                Text(remixCredit)
                    .font(.footnote.bold()).foregroundStyle(KovaTheme.accent)
            }
            if preparingRemix {
                ProgressView("Rendering your duet or stitch…")
                    .tint(KovaTheme.accent)
            }
        }
        .padding(.top, 16)
    }

    private var capturePanel: some View {
        VStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(KovaTheme.banner("glacier"))
                VStack(spacing: 12) {
                    Image(systemName: selectedURL == nil ? "video.badge.plus" : "checkmark.seal.fill")
                        .font(.system(size: 45))
                    Text(selectedURL == nil ? "Your video starts here" : "Ready for publishing")
                        .font(.headline)
                    if let selectedURL {
                        Text(selectedURL.lastPathComponent)
                            .font(.caption).lineLimit(1)
                            .padding(.horizontal, 19)
                    }
                }
                .foregroundStyle(.white)
            }
            .frame(height: 210)

            HStack(spacing: 10) {
                Button {
                    showCamera = true
                } label: {
                    Label("Kova Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity, minHeight: 45)
                }
                .buttonStyle(.borderedProminent)
                .tint(KovaTheme.accent)

                PhotosPicker(selection: $selected, matching: .videos) {
                    Label("Import", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 45)
                }
                .buttonStyle(.bordered)
            }
            .disabled(uploading || preparingRemix || session.user == nil)

            if let originalURL {
                Button {
                    editing = KovaEditingInput(url: originalURL, initialFilter: .original)
                } label: {
                    Label("Edit clip again", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(uploading || preparingRemix)
            }
        }
        .padding(15)
        .kovaGlass(radius: 24)
    }

    private var captionPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("CAPTION").font(.caption.bold()).tracking(1.2)
                Spacer()
                Text("\(caption.count)/2200")
                    .font(.caption2.monospacedDigit()).foregroundStyle(KovaTheme.muted)
            }
            TextField("Write a caption… #gaming @friend", text: $caption, axis: .vertical)
                .lineLimit(3...6)
                .padding(14)
                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                .onChange(of: caption) { _, value in
                    if value.count > 2200 { caption = String(value.prefix(2200)) }
                }
            HStack(spacing: 10) {
                Button {
                    caption += (caption.isEmpty ? "" : " ") + "#"
                } label: { Label("Hashtag", systemImage: "number") }
                Button {
                    caption += (caption.isEmpty ? "" : " ") + "@"
                } label: { Label("Tag user", systemImage: "at") }
            }
            .buttonStyle(.bordered)
            .font(.subheadline.bold())
            Text("Use #hashtags and @username to help people find and credit your posts.")
                .font(.footnote).foregroundStyle(KovaTheme.muted)
        }
    }

    private var descriptionPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("DESCRIPTION").font(.caption.bold()).tracking(1.2)
                Spacer()
                Text("\(description.count)/1200")
                    .font(.caption2.monospacedDigit()).foregroundStyle(KovaTheme.muted)
            }
            TextField("Add details, credits or shoutouts…", text: $description, axis: .vertical)
                .lineLimit(2...5)
                .padding(14)
                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                .onChange(of: description) { _, value in
                    if value.count > 1200 { description = String(value.prefix(1200)) }
                }
        }
    }

    private var soundPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("SOUND").font(.caption.bold()).tracking(1.2)
            Label(musicTitle, systemImage: "music.note")
                .font(.subheadline)
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 15))
            Text("Choose an original Kova loop or a sound you own in the editor.")
                .font(.footnote).foregroundStyle(KovaTheme.muted)
        }
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHO CAN WATCH?").font(.caption.bold()).tracking(1.2)
            Picker("Visibility", selection: $visibility) {
                Text("Everyone").tag("public")
                Text("Followers").tag("followers")
                Text("Only me").tag("private")
            }
            .pickerStyle(.segmented)
            if session.user?.isPrivate == true && visibility == "public" {
                Label("This account is private. Your post won't enter public feeds until you choose a public profile.",
                      systemImage: "lock.shield")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
        }
    }

    private var remixPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            Toggle(isOn: $allowRemix) {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Allow Stitch and Duet", systemImage: "rectangle.on.rectangle")
                        .font(.subheadline.bold())
                    Text("Other creators can use part of this public video.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            .disabled(visibility != "public")
            .tint(KovaTheme.accent)
            Text("Remixing is off by default and requires creator permission. Staff can remove unsafe videos.")
                .font(.footnote).foregroundStyle(KovaTheme.muted)
        }
    }

    private var publishPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                Task { await publish() }
            } label: {
                HStack {
                    Spacer()
                    if uploading {
                        ProgressView().tint(.white)
                    }
                    Label(uploading ? "Publishing…" : "Publish video",
                          systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(KovaTheme.accent)
            .disabled(uploading || preparingRemix || selectedURL == nil ||
                      session.user == nil || !AppConfig.isConfigured)
            if session.user == nil {
                Text("Sign in to record and publish.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            if let message {
                Label(message, systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
        }
    }

    private func cameraDismissed() {
        if let pendingRecorded {
            self.pendingRecorded = nil
            processClip(pendingRecorded.url, initialFilter: pendingRecorded.initialFilter)
        }
    }

    private func importSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let video = try await item.loadTransferable(type: PickedMovie.self) {
                processClip(video.url, initialFilter: .original)
            } else {
                message = "Could not import that video. Try MP4 or MOV."
            }
        } catch { message = error.localizedDescription }
    }

    private func restoreDrafts() {
        guard !accountID.isEmpty else { return }
        caption = KovaLocalState.draft(account: accountID, key: "video.caption")
        description = KovaLocalState.draft(account: accountID, key: "video.description")
        let stored = KovaLocalState.draft(account: accountID, key: "video.visibility")
        if ["public", "followers", "private"].contains(stored) { visibility = stored }
    }

    private func saveDraft(_ value: String, key: String) {
        guard !accountID.isEmpty else { return }
        KovaLocalState.setDraft(value, account: accountID, key: key)
    }

    private func processClip(_ clip: URL, initialFilter: KovaVideoFilter) {
        originalURL = clip
        selectedURL = clip
        if let request = remix.intent {
            Task { await createRemix(using: clip, intent: request) }
        } else {
            editing = KovaEditingInput(url: clip, initialFilter: initialFilter)
        }
    }

    private func createRemix(using local: URL, intent: KovaRemixIntent) async {
        guard !preparingRemix, session.user != nil else { return }
        preparingRemix = true
        defer { preparingRemix = false }
        do {
            let original: KovaVideo = try await session.api.request(
                "/api/videos/\(intent.sourceID)")
            guard original.allowRemix == true, original.visibility == "public",
                  let url = URL(string: original.videoUrl), url.scheme == "https" else {
                throw APIError.server("The creator has disabled remixes of this video.")
            }
            let (download, response) = try await URLSession.shared.download(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw APIError.server("Could not retrieve the original video.")
            }
            let source = FileManager.default.temporaryDirectory
                .appendingPathComponent("kova-source-" + UUID().uuidString)
                .appendingPathExtension(url.pathExtension.lowercased() == "mov" ? "mov" : "mp4")
            try FileManager.default.copyItem(at: download, to: source)
            let edited = try await KovaRemixComposer.make(
                kind: intent.kind, sourceURL: source, creatorURL: local)
            originalURL = edited
            selectedURL = edited
            sourceVideoID = intent.sourceID
            remixType = intent.kind
            remixCredit = intent.kind.capitalized + " with @" + original.handle
            if caption.isEmpty { caption = remixCredit ?? "" }
            remix.clear()
            editing = KovaEditingInput(url: edited, initialFilter: .original)
            message = "Your " + intent.kind + " is ready to edit."
        } catch {
            sourceVideoID = nil
            remixType = nil
            remixCredit = nil
            remix.clear()
            message = error.localizedDescription
        }
    }

    private func publish() async {
        guard !uploading, let url = selectedURL else { return }
        uploading = true
        message = nil
        defer { uploading = false }
        do {
            let published = try await UploadService(api: session.api).upload(
                file: url, caption: caption, description: description,
                visibility: visibility, musicTitle: musicTitle,
                allowRemix: allowRemix && visibility == "public",
                sourceVideoId: sourceVideoID, remixType: remixType)
            message = published.message
            selectedURL = nil
            originalURL = nil
            selected = nil
            caption = ""
            description = ""
            musicTitle = "Original audio"
            sourceVideoID = nil
            remixType = nil
            remixCredit = nil
            allowRemix = false
            visibility = "private"
        } catch {
            message = error.localizedDescription
        }
    }
}
