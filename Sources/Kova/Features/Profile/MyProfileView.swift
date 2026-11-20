import SwiftUI
struct MyProfileView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var ownVideos:[OwnVideo]=[]
    var body:some View {
        NavigationStack {
            ScrollView {
                if let user=session.user {
                    VStack(spacing:15){
                        KovaAvatar(name:user.displayName,size:95).padding(.top,25)
                        Text(user.displayName).font(.kovaHeadline)
                        Text("@"+user.handle).foregroundStyle(KovaTheme.muted)
                        HStack(spacing:30){stat("Followers",value:user.followersCount ?? 0);stat("Following",value:user.followingCount ?? 0)}.padding(.top,10)
                        HStack{NavigationLink("Edit profile"){EditProfileView()};NavigationLink("Settings"){SettingsView()}}.buttonStyle(.borderedProminent).tint(KovaTheme.panel)
                        Text(user.bio?.isEmpty==false ? (user.bio ?? "") : "Make your profile your own.").font(.footnote).foregroundStyle(KovaTheme.muted)
                        Divider().overlay(.white.opacity(0.1))
                        SectionHeading(title:"My videos",subtitle:"Uploads need moderation before appearing publicly")
                        if ownVideos.isEmpty {EmptyState(icon:"film.stack",title:"Nothing posted yet",detail:"Record or upload your first Kova video.").frame(height:250)}
                        else {ForEach(ownVideos){video in HStack{Image(systemName:"film.fill").foregroundStyle(KovaTheme.lavender);Text(video.caption.isEmpty ? "Untitled video" : video.caption).lineLimit(1);Spacer();Text(video.status.uppercased()).font(.caption2).foregroundStyle(video.status=="approved" ? .green : .orange)}.padding(12).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:14))}}
                    }.padding(.horizontal,22)
                } else {EmptyState(icon:"person.crop.circle",title:"Your space awaits",detail:"Sign up to customize a profile, follow creators and post videos.");GradientButton("Leave preview"){session.exitPreview()}.padding(.horizontal,25)}
            }.background(KovaTheme.background).navigationTitle("Profile")
                .task{await load()}
        }
    }
    private func stat(_ title:String,value:Int)->some View {VStack(spacing:4){Text(value.formatted()).font(.title3).bold();Text(title).font(.caption).foregroundStyle(KovaTheme.muted)}}
    private func load() async {guard session.user != nil else{return};if let page:OwnVideoPage=try? await session.api.request("/api/videos/mine"){ownVideos=page.items}}
}
struct OwnVideo:Decodable,Identifiable{let id:String;let caption:String;let videoUrl:String;let status:String;let visibility:String;let createdAt:String}
struct OwnVideoPage:Decodable{let items:[OwnVideo]}
