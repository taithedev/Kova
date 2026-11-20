import SwiftUI

private struct StaffMedia: Decodable, Identifiable {
    let id: String
    let kind: String
    let mime: String
    let previewUrl: String
    let createdAt: String
    let handle: String
}
private struct StaffMediaPage: Decodable { let items: [StaffMedia] }
private struct StaffMediaAction: Encodable { let status: String }
private struct StaffMediaResult: Decodable { let id: String; let status: String }

struct StaffMediaReviewView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var items: [StaffMedia] = []
    @State private var busyIDs: Set<String> = []
    @State private var message: String?

    var body: some View {
        List {
            Section {
                Text("Staff review: submitted profile photos and animated GIF banners stay off public profiles until a moderator approves them.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("AWAITING REVIEW") {
                if items.isEmpty {
                    Label("No profile media pending", systemImage: "checkmark.circle")
                        .foregroundStyle(KovaTheme.muted)
                }
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 13) {
                            if let url = URL(string: item.previewUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("@" + item.handle).font(.headline)
                                Text(item.kind.capitalized + " · " + item.mime)
                                    .font(.footnote).foregroundStyle(KovaTheme.muted)
                                Text(String(item.createdAt.prefix(10)))
                                    .font(.caption).foregroundStyle(KovaTheme.muted)
                            }
                        }
                        HStack(spacing: 12) {
                            Button("Approve") { Task { await decide(item, status: "approved") } }
                                .buttonStyle(.borderedProminent)
                                .tint(KovaTheme.accent)
                            Button("Reject", role: .destructive) {
                                Task { await decide(item, status: "rejected") }
                            }
                            .buttonStyle(.bordered)
                        }
                        .disabled(busyIDs.contains(item.id))
                    }
                    .padding(.vertical, 7)
                }
            }
            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .navigationTitle("Profile media")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            let result: StaffMediaPage = try await session.api.request("/api/staff/media")
            items = result.items
        } catch { message = error.localizedDescription }
    }
    private func decide(_ item: StaffMedia, status: String) async {
        guard !busyIDs.contains(item.id) else { return }
        busyIDs.insert(item.id)
        defer { busyIDs.remove(item.id) }
        do {
            let body = try session.api.encode(StaffMediaAction(status: status))
            let _: StaffMediaResult = try await session.api.request(
                "/api/staff/media/\(item.id)", method: "PATCH", json: body)
            items.removeAll { $0.id == item.id }
            message = status == "approved" ? "Approved for public profile." : "Submission rejected."
        } catch { message = error.localizedDescription }
    }
}
