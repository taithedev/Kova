import SwiftUI
import AVKit

struct ModerationView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var queue: ModerationQueue?
    @State private var error: String?
    @State private var busy = false
    @State private var reportFilter = true
    @State private var preview: ModerationVideo?
    @State private var removal: ModerationVideo?
    @State private var reportedVideoID: String?
    @State private var removalReason = "Community guidelines"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(KovaTheme.accent)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Content moderation")
                                .font(.system(size: 23, weight: .bold))
                            Text("Posts go live immediately. Staff can remove violations.")
                                .font(.subheadline)
                                .foregroundStyle(KovaTheme.muted)
                        }
                    }
                    HStack(spacing: 14) {
                        Label("\(queue?.reports.count ?? 0) open reports", systemImage: "flag")
                        Label("\(queue?.videos.count ?? 0) recent videos", systemImage: "play.rectangle")
                    }
                    .font(.caption)
                    .foregroundStyle(KovaTheme.muted)
                    .padding(.top, 6)
                }
                .padding(.vertical, 8)
            }

            Section {
                Toggle("Show reports first", isOn: $reportFilter)
                    .tint(KovaTheme.accent)
            }

            if reportFilter { reportsSection }
            videosSection
            if !reportFilter { reportsSection }

            Section {
                Text("Removing a video hides it from public discovery and creator profiles. Decisions are recorded in the staff audit log, and the creator is notified. Reports can be resolved or dismissed.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            if let error {
                Section { Text(error).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .navigationTitle("Moderation")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $preview) { clip in
            NavigationStack {
                Group {
                    if let url = URL(string: clip.videoUrl), url.scheme == "https" {
                        VideoPlayer(player: AVPlayer(url: url))
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        ContentUnavailableView("Preview unavailable", systemImage: "video.slash")
                    }
                }
                .navigationTitle("@" + clip.handle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { preview = nil }
                    }
                }
            }
        }
        .confirmationDialog("Remove this video from Kova?", isPresented: Binding(
            get: { removal != nil || reportedVideoID != nil },
            set: { if !$0 { removal = nil; reportedVideoID = nil } }
        )) {
            Button("Remove video", role: .destructive) {
                let id = removal?.id ?? reportedVideoID
                removal = nil
                reportedVideoID = nil
                if let id { Task { await decide(id, status: "rejected") } }
            }
            Button("Cancel", role: .cancel) {
                removal = nil
                reportedVideoID = nil
            }
        } message: {
            Text("The video will no longer appear in Kova feeds or public profiles. The creator will receive a notification.")
        }
    }

    private var reportsSection: some View {
        Section("COMMUNITY REPORTS") {
            if (queue?.reports ?? []).isEmpty {
                Label("No open reports", systemImage: "checkmark.circle")
                    .foregroundStyle(KovaTheme.muted)
            }
            ForEach(queue?.reports ?? []) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(item.reason.replacingOccurrences(of: "_", with: " ").capitalized,
                              systemImage: "flag.fill")
                            .font(.headline)
                        Spacer()
                        Text(item.targetType.capitalized)
                            .font(.caption).foregroundStyle(KovaTheme.muted)
                    }
                    if !item.handle.isEmpty {
                        Text("@" + item.handle)
                            .font(.subheadline).foregroundStyle(KovaTheme.muted)
                    }
                    if !item.caption.isEmpty {
                        Text(item.caption).font(.subheadline).lineLimit(3)
                    }
                    if let detail = item.detail, !detail.isEmpty {
                        Text(detail).font(.subheadline)
                    }
                    Text("Report #" + String(item.id.prefix(8)).uppercased())
                        .font(.caption2.monospaced())
                        .foregroundStyle(KovaTheme.muted)
                    HStack(spacing: 9) {
                        if item.targetType == "video" {
                            Button("Take down video", role: .destructive) {
                                reportedVideoID = item.targetId
                            }
                            .buttonStyle(.bordered)
                            .disabled(busy)
                        }
                        Menu {
                            Button("Mark reviewed", systemImage: "checkmark.circle") {
                                Task { await resolve(item.id, status: "reviewed") }
                            }
                            Button("Dismiss report", systemImage: "xmark.circle") {
                                Task { await resolve(item.id, status: "dismissed") }
                            }
                        } label: {
                            Label("Resolve", systemImage: "ellipsis.circle")
                        }
                        .disabled(busy)
                    }
                    .font(.system(size: 12))
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var videosSection: some View {
        Section("RECENT PUBLISHED VIDEOS") {
            if (queue?.videos ?? []).isEmpty {
                Text("No public videos are currently published.")
                    .foregroundStyle(KovaTheme.muted)
            }
            ForEach(queue?.videos ?? []) { clip in
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("@" + clip.handle).font(.headline)
                        Spacer()
                        Text(clip.visibility.capitalized)
                            .font(.caption).foregroundStyle(KovaTheme.muted)
                    }
                    Text(clip.caption.isEmpty ? "Untitled video" : clip.caption)
                        .font(.subheadline)
                        .lineLimit(3)
                    HStack(spacing: 9) {
                        Button {
                            preview = clip
                        } label: {
                            Label("Preview", systemImage: "play.rectangle")
                        }
                        .buttonStyle(.bordered)
                        Button("Remove", role: .destructive) {
                            removal = clip
                        }
                        .buttonStyle(.bordered)
                        .disabled(busy)
                    }
                }
                .padding(.vertical, 7)
            }
        }
    }

    private func load() async {
        do {
            queue = try await session.api.request("/api/moderation/queue")
            error = nil
        } catch { error = error.localizedDescription }
    }
    private func decide(_ id: String, status: String) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(VideoModerationDecision(
                status: status, reason: removalReason))
            let _: VideoModerationResult = try await session.api.request(
                "/api/moderation/videos/\(id)", method: "PATCH", json: payload)
            await load()
        } catch { error = error.localizedDescription }
    }
    private func resolve(_ id: String, status: String) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(ReportResolution(status: status))
            let _: VideoModerationResult = try await session.api.request(
                "/api/moderation/reports/\(id)", method: "PATCH", json: payload)
            await load()
        } catch { error = error.localizedDescription }
    }
}
private struct VideoModerationDecision: Encodable {
    let status: String
    let reason: String
}
private struct ReportResolution: Encodable {
    let status: String
}
private struct VideoModerationResult: Decodable {
    let id: String
    let status: String
}
private struct ModerationQueue: Decodable {
    let videos: [ModerationVideo]
    let reports: [ModerationReport]
}
private struct ModerationVideo: Decodable, Identifiable {
    let id: String
    let caption: String
    let videoUrl: String
    let status: String
    let visibility: String
    let createdAt: String
    let handle: String
}
private struct ModerationReport: Decodable, Identifiable {
    let id: String
    let targetType: String
    let targetId: String
    let reason: String
    let detail: String?
    let createdAt: String
    let handle: String
    let caption: String
}
