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
    @State private var selectedTags: [String] = []
    @State private var preparingRemix = false
    @State private var sourceVideoID: String?
    @State private var remixType: String?
    @State private var remixCredit: String?
    @State private var taggedAccount = ""
    @State private var visibility = "private"
    @State private var showCamera = false
    @State private var uploading = false
    @State private var message: String?

    private var accountID: String { session.user?.id ?? "" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 19) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CREATE / KOVA")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1.7)
                            .foregroundStyle(KovaTheme.muted)
                        Text("Make your next video.")
                            .font(.system(size: 32, weight: .heavy))
                            .tracking(-1.2)
                        Text("Record with our camera, add your effects, and share it.")
                        if let intent = remix.intent {
                            Label("Create a " + intent.kind.capitalized + " with @" + intent.sourceHandle,
                                  systemImage: "rectangle.on.rectangle")
                                .font(.subheadline.bold())
                                .foregroundStyle(KovaTheme.accent)
                        }
                        if let remixCredit {
                            Text(remixCredit)
                                .font(.caption.bold())
                                .foregroundStyle(KovaTheme.accent)
                        }
                        if preparingRemix {
                            ProgressView("Rendering your duet or stitch…").tint(KovaTheme.accent)
                        }
                            .font(.subheadline).foregroundStyle(KovaTheme.muted)
                    }
                    .padding(.top, 18)

                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(KovaTheme.banner("glacier"))
                            VStack(spacing: 14) {
                                Image(systemName: selectedURL == nil ? "video.badge.plus" : "checkmark.seal.fill")
                                    .font(.system(size: 48))
                                    .symbolRenderingMode(.hierarchical)
                                Text(selectedURL == nil ? "Your video starts here" : "Ready for your caption")
                                    .font(.headline)
                                if let selectedURL {
                                    Text(selectedURL.lastPathComponent)
                                        .font(.footnote)
                                        .lineLimit(1)
                                        .padding(.horizontal, 22)
                                }
                            }
                            .foregroundStyle(.white)
                        }
                        .frame(height: 220)

                        HStack(spacing: 11) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Kova Camera", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(KovaTheme.accent)
                            .disabled(uploading || session.user == nil)

                            PhotosPicker(selection: $selected, matching: .videos) {
                                Label("Import", systemImage: "photo.on.rectangle.angled")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                            }
                            .buttonStyle(.bordered)
                            .disabled(uploading || session.user == nil)
                        }
                        .font(.system(size: 14, weight: .bold))

                        if let source = originalURL {
                            Button {
                                editing = KovaEditingInput(url: source, initialFilter: .original)
                            } label: {
                                Label("Edit clip again", systemImage: "slider.horizontal.3")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(uploading)
                        }
                    }
                    .padding(15)
                    .kovaGlass(radius: 24)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("CAPTION").font(.caption.bold()).tracking(1.2)
                            Spacer()
                            Text("\(caption.count)/2200")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(KovaTheme.muted)
                        }
                        TextField("Tell your story…  #gaming #music", text: $caption, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(15)
                            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                            .onChange(of: description) { _, value in
                if !accountID.isEmpty {
                    KovaLocalState.setDraft(value, account: accountID, key: "video.description")
                }
            }
            .onChange(of: caption) { _, value in
                                if value.count > 2200 { caption = String(value.prefix(2200)) }
                            }
                        HStack(spacing: 9) {
                            Button {
                                if !caption.contains("#") { caption += (caption.isEmpty ? "" : " ") + "#"}
                            } label: {
                                Label("Hashtag", systemImage: "number")
                            }
                            .buttonStyle(.bordered)
                            Button {
                                caption += (caption.isEmpty ? "" : " ") + "@"
                            } label: {
                                Label("Mention", systemImage: "at")
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.subheadline.bold())
                        Text("Use #hashtags and @username mentions. Mentioned accounts can receive a notification.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("VIDEO DESCRIPTION").font(.caption.bold()).tracking(1.2)
                            Spacer()
                            Text("\(description.count)/1200")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(KovaTheme.muted)
                        }
                        TextField("Add more details, credit sources, mention friends…",
                                  text: $description, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(14)
                            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                            .onChange(of: description) { _, value in
                                if value.count > 1200 { description = String(value.prefix(1200)) }
                            }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SOUND").font(.caption.bold()).tracking(1.2)
                        Label(musicTitle, systemImage: "music.note")
                            .font(.subheadline)
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 15))
                        Text("Use original audio or audio you own or have permission to include. Select sounds in the video editor.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WHO CAN WATCH?").font(.caption.bold()).tracking(1.2)
                        Picker("Visibility", selection: $visibility) {
                            Text("Everyone").tag("public")
                            Text("Followers").tag("followers")
                            Text("Only me").tag("private")
                        }
                        .pickerStyle(.segmented)
                        if session.user?.isPrivate == true && visibility == "public" {
                            Label("Your account is private. Public discovery stays off until you choose a public profile.",
                                  systemImage: "lock.shield")
                                .font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                    }

                    Toggle(isOn: $allowRemix) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Allow Stitch and Duet", systemImage: "rectangle.on.rectangle")
                                .font(.subheadline.bold())
                            Text("Other creators may use a clip of this public video in their videos.")
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .tint(KovaTheme.accent)
                    .disabled(visibility != "public")
                    GlassPanel {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.shield")
                                .foregroundStyle(KovaTheme.accent)
                            Text("Videos publish when the upload completes—no approval queue. Staff can remove policy violations, and other members can report unsafe content.")
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }

                    Button {
                        Task { await publish() }
                    } label: {
                        HStack {
                            Spacer()
                            if uploading {
                                ProgressView().tint(.white).padding(.trailing, 9)
                            }
                            Label(uploading ? "Uploading and publishing…" : "Publish video",
                                  systemImage: "arrow.up.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .frame(height: 51)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KovaTheme.accent)
                    .disabled(uploading || preparingRemix || selectedURL == nil || session.user == nil ||
                              !AppConfig.isConfigured || caption.count > 2200)
                    if session.user == nil {
                        Text("Sign in to start recording and posting.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    if let message {
                        Label(message, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .background(KovaTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCamera, onDismiss: {
                if let pendingRecorded {
                    self.pendingRecorded = nil
                    processClip(pendingRecorded.url, initialFilter: pendingRecorded.initialFilter)
                }
            }) {
                KovaRecorderView { video, preset in
                    originalURL = video
                    selectedURL = video
                    pendingRecorded = KovaEditingInput(
                        url: video,
                        initialFilter: KovaVideoFilter(rawValue: preset) ?? .original
                    )
                }
            }
            .sheet(item: $editing) { source in
                KovaEditorView(input: source) { output, soundCredit in
                    selectedURL = output
                    musicTitle = soundCredit
                    message = "Video edited successfully with " + soundCredit + "."
                }
            }
            .onChange(of: selected) { _, new in
                Task {
                    guard let new else { return }
                    do {
                        if let video = try await new.loadTransferable(type: PickedMovie.self) {
                            processClip(video.url, initialFilter: .original)
                        } else {
                            message = "Could not import that video. Try MP4 or MOV."
                        }
                    } catch { message = error.localizedDescription }
                }
            }
            .task {
                guard !accountID.isEmpty else { return }
                caption = KovaLocalState.draft(account: accountID, key: "video.caption")
                description = KovaLocalState.draft(account: accountID, key: "video.description")
                let stored = KovaLocalState.draft(account: accountID, key: "video.visibility")
                if ["public", "followers", "private"].contains(stored) { visibility = stored }
            }
            .onChange(of: caption) { _, value in
                if !accountID.isEmpty {
                    KovaLocalState.setDraft(value, account: accountID, key: "video.caption")
                }
            }
            .onChange(of: visibility) { _, value in
                if !accountID.isEmpty {
                    KovaLocalState.setDraft(value, account: accountID, key: "video.visibility")
                }
            }
        }
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
