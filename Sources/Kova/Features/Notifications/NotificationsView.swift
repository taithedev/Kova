import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var items: [KovaNotification] = []
    @State private var status: String?
    var body: some View {
        List {
            if let status {
                Section { Text(status).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
            Section {
                Button {
                    Task { await markRead() }
                } label: {
                    Label("Mark all read", systemImage: "checkmark.circle")
                }
                .disabled(items.allSatisfy { $0.isRead })
            }
            Section("ACTIVITY") {
                if items.isEmpty {
                    Text("No notifications yet.")
                        .foregroundStyle(KovaTheme.muted)
                }
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.isRead ? "bell" : "bell.badge")
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.body ?? item.kind).font(.subheadline)
                            Text(item.createdAt.prefix(10))
                                .font(.caption2).foregroundStyle(KovaTheme.muted)
                        }
                        Spacer()
                        if !item.isRead {
                            Circle().fill(.white).frame(width: 7, height: 7)
                        }
                    }
                    .padding(.vertical, 7)
                }
            }
        }
        .navigationTitle("Notifications")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
    }
    private func load() async {
        guard session.user != nil else { return }
        do {
            let result: NotificationPage = try await session.api.request("/api/notifications")
            items = result.items
        } catch { status = error.localizedDescription }
    }
    private func markRead() async {
        do {
            let _: NotificationMarkResult = try await session.api.request("/api/notifications/read-all", method: "POST")
            status = "Notifications marked as read."
            await load()
        } catch { status = error.localizedDescription }
    }
}
private struct NotificationMarkResult: Decodable { let markedRead: Int }
