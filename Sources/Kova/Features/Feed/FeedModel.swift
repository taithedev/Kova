import Foundation
@MainActor final class FeedModel:ObservableObject {
    @Published var videos:[KovaVideo]=[]
    @Published var isLoading=false
    @Published var errorMessage:String?
    @Published var mode="for-you"
    private var cursor:String?
    var hasMore:Bool { cursor != nil }
    func loadMore(api:APIClient,preview:Bool) async {
        guard !isLoading && !preview && cursor != nil else {return}
        await load(api:api,preview:false,reset:false)
    }
    func load(api:APIClient,preview:Bool,reset:Bool=true) async {
        if isLoading {return};isLoading=true;defer{isLoading=false}
        if reset {videos=[];cursor=nil;errorMessage=nil}
        if preview && mode == "following" { videos=[]; return }
        do {
            var path="/api/feed?mode=\(mode)"
            if let cursor {path+="&cursor=\(cursor)"}
            let page:VideoPage=try await api.request(path)
            videos+=page.items;cursor=page.nextCursor
        }catch{errorMessage=error.localizedDescription}
    }
    func like(_ id:String,api:APIClient) async {
        guard let index=videos.firstIndex(where:{$0.id==id}) else{return}
        let liked=videos[index].liked
        do {
            let _:LikeResult=try await api.request("/api/videos/\(id)/like",method:liked ? "DELETE":"POST")
            videos[index].liked = !liked
            videos[index].likesCount += liked ? -1 : 1
        }catch{errorMessage=error.localizedDescription}
    }
    func repost(_ id: String, api: APIClient) async {
        guard let index = videos.firstIndex(where: { $0.id == id }) else { return }
        let alreadyReposted = videos[index].reposted
        do {
            let result: RepostResult = try await api.request(
                "/api/videos/\(id)/repost", method: alreadyReposted ? "DELETE" : "POST")
            guard let updated = videos.firstIndex(where: { $0.id == id }) else { return }
            videos[updated].reposted = result.reposted
            videos[updated].repostsCount = result.repostsCount
        } catch { errorMessage = error.localizedDescription }
    }
    func notInterested(_ id: String, api: APIClient) async {
        do {
            let _: VideoPreferenceResult = try await api.request(
                "/api/videos/\(id)/not-interested", method: "POST")
            videos.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }
    func bookmark(_ id:String,api:APIClient) async {
        guard let index=videos.firstIndex(where:{$0.id==id}) else{return}
        let saved=videos[index].bookmarked
        do {
            let _:BookmarkResult=try await api.request("/api/videos/\(id)/bookmark",method:saved ? "DELETE":"POST")
            videos[index].bookmarked = !saved
        }catch{errorMessage=error.localizedDescription}
    }
}
struct LikeResult:Decodable{let liked:Bool}
struct BookmarkResult:Decodable{let bookmarked:Bool}

struct RepostResult: Decodable { let reposted: Bool; let repostsCount: Int }
struct VideoPreferenceResult: Decodable { let hidden: Bool }
