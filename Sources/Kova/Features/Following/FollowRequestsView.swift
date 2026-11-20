import SwiftUI

struct FollowRequestsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var requests: [FollowRequest] = []
    @State private var status: String?
    @State private var busyIDs: Set<String> = []

    var body: some View {
        List {
            if requests.isEmpty {
                Text("No pending follow requests.")
                    .foregroundStyle(KovaTheme.muted)
            }
            ForEach(requests) { request in
                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 11) {
                        KovaAvatar(name: request.displayName)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.displayName).bold()
                            Text("@" + request.handle).font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    HStack(spacing: 12) {
                        Button("Accept") { Task { await decide(request, accept: true) } }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
                            .foregroundStyle(.black)
                        Button("Decline", role: .destructive) { Task { await decide(request, accept: false) } }
                            .buttonStyle(.bordered)
                    }
                    .disabled(busyIDs.contains(request.id))
                }
                .padding(.vertical, 5)
            }
            if let status { Text(status).font(.footnote).foregroundStyle(KovaTheme.muted) }
        }
        .navigationTitle("Follow requests")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
    }
    private func load() async {
        do {
            let result: FollowRequestPage = try await session.api.request("/api/follows/requests")
            requests = result.items
        } catch { status = error.localizedDescription }
    }
    private func decide(_ request: FollowRequest, accept: Bool) async {
        guard !busyIDs.contains(request.id) else { return }
        busyIDs.insert(request.id)
        defer { busyIDs.remove(request.id) }
        do {
            let suffix = accept ? "" : "/reject"
            let _: FollowStatus = try await session.api.request(
                "/api/follows/requests/\(request.id)\(suffix)", method: "POST"
            )
            status = accept ? "Follow request accepted." : "Follow request declined."
            await load()
        } catch { status = error.localizedDescription }
    }
}
struct FollowRequest: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let createdAt: String
}
struct FollowRequestPage: Decodable { let items: [FollowRequest] }
struct FollowStatus: Decodable { let status: String }
