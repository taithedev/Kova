import SwiftUI
struct UserProfileView:View {
    @EnvironmentObject private var session:SessionStore
    let handle:String
    @State private var result:ProfileResponse?
    @State private var message:String?
    @State private var isFollowing=false
    var body:some View {
        ScrollView{
            if let result {
                VStack(spacing:16){
                    KovaAvatar(name:result.profile.displayName,size:92).padding(.top,30)
                    Text(result.profile.displayName).font(.kovaHeadline)
                    Text("@"+result.profile.handle).foregroundStyle(KovaTheme.muted)
                    Text(result.profile.bio ?? "").font(.subheadline)
                    Text("\(result.profile.followersCount ?? 0) followers · \(result.profile.followingCount ?? 0) following").foregroundStyle(KovaTheme.muted).font(.caption)
                    GradientButton(isFollowing ? "Following" : "Follow",icon:isFollowing ? "checkmark":"plus") {Task{await follow()}}.padding(.horizontal,30)
                    if result.profile.isPrivate && !isFollowing {EmptyState(icon:"lock.shield",title:"Private account",detail:"Follow to request access.").frame(height:250)}
                    else {ForEach(result.videos){video in HStack{Image(systemName:"play.rectangle.fill");Text(video.caption.isEmpty ? "Video" : video.caption).lineLimit(2)}.padding(15).frame(maxWidth:.infinity,alignment:.leading).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:14))}}
                    if let message {Text(message).foregroundStyle(KovaTheme.muted)}
                }.padding(20)
            } else {LoadingPanel()}
        }.background(KovaTheme.background).navigationTitle("Profile").task{await load()}
    }
    private func load() async {do{result=try await session.api.request("/api/users/\(handle)");isFollowing=result?.profile.isFollowing ?? false}catch{message=error.localizedDescription}}
    private func follow() async {
        guard session.user != nil else{message="Sign in first.";return}
        do{let r:FollowResult=try await session.api.request("/api/users/\(handle)/follow",method:isFollowing ? "DELETE":"POST");isFollowing=r.status=="accepted";if r.status=="pending"{message="Follow request sent."};if !isFollowing && r.status==nil {message="Unfollowed."}}
        catch{message=error.localizedDescription}
    }
}
private struct FollowResult:Decodable{let status:String?;let following:Bool?}
