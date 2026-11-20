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
                    Group {
                        if let ticketID = item.ticketId,
                           item.kind == "support_reply" || item.kind == "support_status" {
                            NavigationLink {
                                SupportTicketThreadView(id: ticketID)
                            } label: {
                                notificationRow(item)
                            }
                        } else {
                            notificationRow(item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
    }
    @ViewBuilder private func notificationRow(_ item: KovaNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.ticketId != nil ? "lifepreserver" :
                  (item.isRead ? "bell" : "bell.badge"))
                .foregroundStyle(item.isRead ? KovaTheme.muted : KovaTheme.accent)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.body ?? item.kind)
                    .font(.subheadline)
                Text(String(item.createdAt.prefix(10)))
                    .font(.caption2)
                    .foregroundStyle(KovaTheme.muted)
            }
            Spacer()
            if !item.isRead {
                Circle().fill(KovaTheme.accent).frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 7)
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
