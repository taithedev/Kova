import SwiftUI
struct InboxView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var notifications:[KovaNotification]=[]
    var body:some View {
        NavigationStack{
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    SectionHeading(title:"Inbox",subtitle:"Notifications and community updates")
                    GlassPanel{HStack(spacing:13){Image(systemName:"hand.raised.slash").font(.title2).foregroundStyle(KovaTheme.aqua);VStack(alignment:.leading){Text("Safer messaging").font(.headline);Text("Direct messages and group chats are not enabled yet. Accounts for teens start with DMs off.").font(.footnote).foregroundStyle(KovaTheme.muted)}}}
                    SectionHeading(title:"Notifications")
                    if notifications.isEmpty {EmptyState(icon:"bell.badge",title:"All caught up",detail:"You'll see account updates here when they're available.").frame(height:260)}
                    else {ForEach(notifications){n in HStack{Image(systemName:"bell.fill").foregroundStyle(KovaTheme.lavender);Text(n.body ?? n.kind);Spacer()}.padding(15).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:16))}}
                }.padding(20)
            }.background(KovaTheme.background).task{await load()}
        }
    }
    private func load()async{guard session.user != nil else{return};if let r:NotificationPage=try? await session.api.request("/api/notifications"){notifications=r.items}}
}
