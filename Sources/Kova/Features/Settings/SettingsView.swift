import SwiftUI
struct SettingsView:View {
    @EnvironmentObject private var session:SessionStore
    var body:some View {
        List {
            Section("Account"){
                Label("Privacy-first settings",systemImage:"lock.shield")
                if let user=session.user {LabeledContent("Age band",value:user.ageBand ?? "Unknown")}
                LabeledContent("Messages",value:"Disabled")
                NavigationLink { BookmarksView() } label: { Label("Saved videos",systemImage:"bookmark") }
                NavigationLink { FollowRequestsView() } label: { Label("Follow requests",systemImage:"person.crop.circle.badge.checkmark") }
                if session.user?.role == "admin" || session.user?.role == "moderator" {
                    NavigationLink { ModerationView() } label: { Label("Moderation queue",systemImage:"shield.checkered") }
                }
            }
            Section("Kova"){
                Label("Community Guidelines",systemImage:"hand.raised")
                Text("Respect others. No bullying, harassment, spam, or sharing personal information without permission.").font(.footnote).foregroundStyle(KovaTheme.muted)
                LabeledContent("App",value:"Kova 0.1.0")
            }
            Section {Button("Sign out",role:.destructive){Task{await session.signOut()}}}
        }.navigationTitle("Settings")
    }
}
