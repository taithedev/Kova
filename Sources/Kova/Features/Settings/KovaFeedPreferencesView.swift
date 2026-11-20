import SwiftUI

private struct KovaFeedPreferenceCount: Decodable { let hiddenCount: Int }
private struct KovaFeedReset: Decodable { let reset: Bool; let cleared: Int }

struct KovaFeedPreferencesView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var hiddenCount: Int?
    @State private var resetting = false
    @State private var status: String?
    @State private var confirmReset = false

    var body: some View {
        List {
            Section("HOW FOR YOU WORKS") {
                Label("Recently published videos get a freshness boost.", systemImage: "clock")
                Label("Real likes, comments and reposts affect ranking, with limits.", systemImage: "heart")
                Label("Following creators provides a modest boost.", systemImage: "person.2")
                Label("Repeated posts by one creator are reduced.", systemImage: "square.stack.3d.up")
                Label("Hidden and blocked accounts stay out of recommendations.", systemImage: "eye.slash")
                Text("Kova does not profile sensitive personal characteristics to rank content. You control your interests by following creators and marking videos Not interested.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("YOUR CONTROLS") {
                LabeledContent("Videos marked Not interested",
                               value: hiddenCount.map(String.init) ?? "—")
                Button("Reset hidden video choices") {
                    confirmReset = true
                }
                .disabled(resetting || hiddenCount == 0 || session.user == nil)
            }
            Section {
                Text("Your Following feed stays in chronological order. The default For You feed favors fresher posts and creator diversity rather than endless watch-time tracking.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            if let status {
                Section { Text(status).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .navigationTitle("For You")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog("Reset Not interested choices?", isPresented: $confirmReset) {
            Button("Reset choices", role: .destructive) { Task { await reset() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your hidden video list will be cleared. Blocked users stay blocked.")
        }
    }
    private func load() async {
        guard session.user != nil else { return }
        do {
            let response: KovaFeedPreferenceCount = try await session.api.request("/api/feed/preferences")
            hiddenCount = response.hiddenCount
        } catch { status = error.localizedDescription }
    }
    private func reset() async {
        guard !resetting else { return }
        resetting = true
        defer { resetting = false }
        do {
            let result: KovaFeedReset = try await session.api.request(
                "/api/feed/preferences", method: "DELETE")
            hiddenCount = 0
            status = "Reset \\(result.cleared) hidden-video choices."
        } catch { status = error.localizedDescription }
    }
}
