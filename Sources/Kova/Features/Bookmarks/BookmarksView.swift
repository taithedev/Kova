import SwiftUI
struct BookmarksView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var videos:[KovaVideo]=[]
    var body:some View {
        ScrollView{
            if videos.isEmpty {EmptyState(icon:"bookmark",title:"Nothing saved",detail:"Save videos to see them here.")}
            else {LazyVStack(spacing:10){ForEach(videos){video in HStack{Image(systemName:"play.rectangle.fill");VStack(alignment:.leading){Text(video.caption).lineLimit(2);Text("@"+video.handle).foregroundStyle(KovaTheme.muted)};Spacer()}.padding(15).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:14))}}.padding()}
        }.navigationTitle("Saved").task{await load()}
    }
    private func load() async {guard session.user != nil else{return};if let response:VideoPage=try? await session.api.request("/api/bookmarks"){videos=response.items}}
}
