import SwiftUI
struct UserProfileView:View {
    @EnvironmentObject private var session:SessionStore
    let handle:String
    @State private var result:ProfileResponse?
    @State private var message:String?
    @State private var isFollowing=false
    @State private var requested=false
    @State private var showReport=false
    @State private var showBlockConfirmation=false
    @State private var didBlock=false
    var body:some View {
        ScrollView{
            if didBlock {
                EmptyState(icon:"hand.raised",title:"Account blocked",detail:"You will not see this account or its videos.").frame(height:350)
            } else if let result {
                VStack(spacing:16){
                    KovaAvatar(name:result.profile.displayName,size:92).padding(.top,30)
                    Text(result.profile.displayName).font(.kovaHeadline)
                    Text("@"+result.profile.handle).foregroundStyle(KovaTheme.muted)
                    Text(result.profile.bio ?? "").font(.subheadline)
                    Text("\(result.profile.followersCount ?? 0) followers · \(result.profile.followingCount ?? 0) following").foregroundStyle(KovaTheme.muted).font(.caption)
                    GradientButton(requested ? "Requested" : (isFollowing ? "Following" : "Follow"),icon:requested ? "clock" : (isFollowing ? "checkmark" : "plus")) {
                        if !requested {Task{await follow()}}
                    }.padding(.horizontal,30).disabled(requested)
                    if result.profile.isPrivate && !isFollowing {EmptyState(icon:"lock.shield",title:"Private account",detail:"Follow to request access.").frame(height:250)}
                    else {ForEach(result.videos){video in HStack{Image(systemName:"play.rectangle.fill");Text(video.caption.isEmpty ? "Video" : video.caption).lineLimit(2)}.padding(15).frame(maxWidth:.infinity,alignment:.leading).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:14))}}
                    if let message {Text(message).foregroundStyle(KovaTheme.muted)}
                }.padding(20)
            } else {LoadingPanel()}
        }
        .background(KovaTheme.background)
        .navigationTitle("Profile")
        .task{await load()}
        .toolbar {
            ToolbarItem(placement:.topBarTrailing) {
                if session.user != nil && session.user?.handle != handle {
                    Menu {
                        Button("Report profile",systemImage:"flag"){showReport=true}
                        Button("Block account",systemImage:"hand.raised",role:.destructive){showBlockConfirmation=true}
                    } label: {Image(systemName:"ellipsis").foregroundStyle(.white)}
                }
            }
        }
        .sheet(isPresented:$showReport) {
            if let id=result?.profile.id {ReportSheet(targetType:"user",targetID:id)}
        }
        .confirmationDialog("Block this account?",isPresented:$showBlockConfirmation) {
            Button("Block account",role:.destructive){Task{await block()}}
        } message:{Text("You won't see this person's videos or messages.")}

    }
    private func load() async {do{result=try await session.api.request("/api/users/\(handle)");isFollowing=result?.profile.isFollowing ?? false}catch{message=error.localizedDescription}}
    private func follow() async {
        guard session.user != nil else{message="Sign in first.";return}
        do{let r:FollowResult=try await session.api.request("/api/users/\(handle)/follow",method:isFollowing ? "DELETE":"POST");isFollowing=r.status=="accepted";if r.status=="pending"{requested=true;message="Follow request sent."};if !isFollowing && r.status==nil {message="Unfollowed."}}
        catch{message=error.localizedDescription}
    }
    private func block() async {
        guard session.user != nil else {return}
        do {
            let payload=try session.api.encode(BlockProfilePayload(handle:handle))
            let _:BlockProfileResponse=try await session.api.request("/api/users/me/block",method:"POST",json:payload)
            didBlock=true
            message="Account blocked."
        } catch {message=error.localizedDescription}
    }
}
private struct BlockProfilePayload:Encodable{let handle:String}
private struct BlockProfileResponse:Decodable{let blocked:Bool}
private struct FollowResult:Decodable{let status:String?;let following:Bool?}
