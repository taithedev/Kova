import SwiftUI
struct FeedView:View {
    @EnvironmentObject private var session:SessionStore
    @StateObject private var model=FeedModel()
    @SceneStorage("kova.feed.activeVideo") private var activeID:String?
    @SceneStorage("kova.feed.mode") private var savedMode="for-you"
    @State private var commentsVideo:KovaVideo?
    @State private var reportVideo:KovaVideo?
    @State private var needsSignIn=false
    var body:some View {
        GeometryReader { geo in
            ZStack(alignment:.top) {
                KovaTheme.background.ignoresSafeArea()
                if model.videos.isEmpty && model.isLoading {LoadingPanel(label:"Opening Kova")} else if model.videos.isEmpty {
                    VStack(spacing:16) {
                        EmptyState(icon:"play.square.stack",title:"No published videos yet",detail:"Published videos from real creators will appear here.")
                        Button("Refresh feed") {
                            Task { await model.load(api:session.api,preview:session.isPreviewing) }
                        }.font(.system(size:14,weight:.semibold)).foregroundStyle(KovaTheme.accent)
                    }
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing:0) {
                            ForEach(Array(model.videos.enumerated()),id:\.element.id){idx,video in
                                VideoCard(video:video,demoIndex:idx,isActive:activeID == video.id,
                                    like:{interact{await model.like(video.id,api:session.api)}},
                                    bookmark:{interact{await model.bookmark(video.id,api:session.api)}},
                                    comment:{if !session.isPreviewing {commentsVideo=video} else {needsSignIn=true}},
                                    report:{if !session.isPreviewing {reportVideo=video}},
                                    repost:{interact{await model.repost(video.id,api:session.api)}},
                                    notInterested:{interact{await model.notInterested(video.id,api:session.api)}},
                                    follow:{interact{
                                        do {
                                            let response:FollowStatus=try await session.api.request("/api/users/\(video.handle)/follow",method:"POST")
                                            model.errorMessage=response.status=="pending" ? "Follow request sent." : "Now following @\(video.handle)."
                                        } catch {model.errorMessage=error.localizedDescription}
                                    }})
                                    .frame(width:geo.size.width,height:geo.size.height)
                                    .id(video.id)
                                    .onAppear {
                                        if idx >= model.videos.count - 2 {
                                            Task { await model.loadMore(api:session.api,preview:session.isPreviewing) }
                                        }
                                    }
                            }
                        }.scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollPosition(id:$activeID)
.sensoryFeedback(.selection, trigger:activeID)
                    .animation(.easeInOut(duration: 0.18), value: model.videos.count)
                    .refreshable {
                        activeID=nil
                        await model.load(api:session.api,preview:session.isPreviewing)
                    }
                    .onAppear{if activeID == nil {activeID=model.videos.first?.id}}
                    .onChange(of:model.videos.count){_,_ in if activeID == nil {activeID=model.videos.first?.id}}
                }
                HStack(spacing:24){
                    Button("Following"){changeMode("following")}.foregroundStyle(model.mode=="following" ? .white : KovaTheme.muted)
                    Button("For You"){changeMode("for-you")}.foregroundStyle(model.mode=="for-you" ? .white : KovaTheme.muted)
                }
                .font(.system(size:16,weight:.bold)).padding(12)
                .background(.ultraThinMaterial,in:Capsule())
                .padding(.top,10)
                if session.isPreviewing {VStack{Spacer();Text("BROWSING AS A GUEST").font(.caption2).bold().padding(8).background(.black.opacity(0.5),in:Capsule()).padding(.bottom,12)}}
            }
        }
        .task(id:session.user?.id){
            model.mode = savedMode
            await model.load(api:session.api,preview:session.isPreviewing)
        }
        .sheet(item:$commentsVideo){CommentsSheet(video:$0)}
        .sheet(item:$reportVideo){ReportSheet(targetType:"video",targetID:$0.id)}
        .alert("Sign in to interact",isPresented:$needsSignIn){Button("OK",role:.cancel) {}} message:{Text("Create a 13+ account to like, follow, save or comment.")}
        .alert("Kova",isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0{model.errorMessage=nil}})){Button("OK",role:.cancel){model.errorMessage=nil}} message:{Text(model.errorMessage ?? "")}
    }
    private func changeMode(_ mode:String){
        if mode=="following" && session.user == nil {needsSignIn=true;return}
        model.mode=mode;savedMode=mode;activeID=nil;Task{await model.load(api:session.api,preview:session.isPreviewing)}
    }
    private func interact(_ operation:@escaping @MainActor () async -> Void){
        guard session.user != nil else {needsSignIn=true;return}
        Task{await operation()}
    }
}
