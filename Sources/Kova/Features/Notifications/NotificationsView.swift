import SwiftUI
struct NotificationsView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var items:[KovaNotification]=[]
    var body:some View {
        List {
            if items.isEmpty {Text("No notifications yet.").foregroundStyle(.secondary)}
            ForEach(items){n in Label(n.body ?? n.kind,systemImage:n.isRead ? "bell" : "bell.badge.fill")}
        }.navigationTitle("Notifications").task{if let result:NotificationPage=try? await session.api.request("/api/notifications"){items=result.items}}
    }
}
