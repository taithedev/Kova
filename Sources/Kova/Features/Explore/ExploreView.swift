import SwiftUI
struct ExploreView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var query=""
    @State private var result=SearchResponse(users:[],videos:[])
    @State private var errorMessage:String?
    var body:some View {
        NavigationStack{
            ScrollView{
                VStack(alignment:.leading,spacing:22) {
                    Text("Discover").font(.kovaDisplay)
                    HStack{Image(systemName:"magnifyingglass");TextField("People, captions, ideas",text:$query).textInputAutocapitalization(.never).autocorrectionDisabled()}.padding(16).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:18))
                    if session.isPreviewing {
                        GlassPanel {VStack(alignment:.leading,spacing:9){Label("Explore Kova",systemImage:"sparkles").font(.kovaHeadline);Text("Search will become available after connecting the API and signing in.").foregroundStyle(KovaTheme.muted)}}
                    } else if query.count<2 {
                        VStack(alignment:.leading,spacing:12){SectionHeading(title:"Find your community",subtitle:"Search by username or video caption");ForEach(["#creativity","#music","#gaming","#community"],id:\.self){tag in Text(tag).font(.system(size:15,weight:.bold)).foregroundStyle(KovaTheme.lavender).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:13))}}
                    } else {
                        if !result.users.isEmpty {SectionHeading(title:"People");ForEach(result.users){u in NavigationLink {UserProfileView(handle:u.handle)} label:{HStack{KovaAvatar(name:u.displayName);VStack(alignment:.leading){Text(u.displayName).foregroundStyle(.white).bold();Text("@"+u.handle).foregroundStyle(KovaTheme.muted).font(.caption)};Spacer();Image(systemName:"chevron.right").foregroundStyle(KovaTheme.muted)}}.padding(10).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:16))}}
                        if !result.videos.isEmpty {SectionHeading(title:"Videos");ForEach(result.videos){v in HStack{Image(systemName:"play.square.fill").font(.title).foregroundStyle(KovaTheme.lavender);VStack(alignment:.leading){Text(v.caption).lineLimit(2);Text("@"+v.handle).font(.caption).foregroundStyle(KovaTheme.muted)};Spacer()}.padding(12).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:16))}}
                        if result.users.isEmpty && result.videos.isEmpty {Text(errorMessage ?? "Nothing found yet.").foregroundStyle(KovaTheme.muted)}
                    }
                }.padding(18)
            }.background(KovaTheme.background)
            .task(id:query){guard query.count>=2 && !session.isPreviewing else {result=SearchResponse(users:[],videos:[]);return};try? await Task.sleep(for:.milliseconds(350));if Task.isCancelled{return};await search()}
        }
    }
    private func search() async {
        guard let q=query.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) else{return}
        do{result=try await session.api.request("/api/search?q=\(q)")}catch{errorMessage=error.localizedDescription}
    }
}
