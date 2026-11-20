import SwiftUI
struct ModerationView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var queue:ModerationQueue?
    @State private var error:String?
    var body:some View {
        List {
            Section("Pending videos"){
                if queue?.videos.isEmpty ?? true {Text("No videos awaiting review")}
                ForEach(queue?.videos ?? []){item in VStack(alignment:.leading){Text("@"+item.handle).bold();Text(item.caption);HStack{Button("Approve"){Task{await decide(item.id,status:"approved")}};Button("Reject",role:.destructive){Task{await decide(item.id,status:"rejected")}}}}}
            }
            Section("Reports") {ForEach(queue?.reports ?? []){r in VStack(alignment:.leading){Text(r.reason).bold();Text(r.targetType+" · "+r.targetId).font(.caption)}}}
            if let error {Text(error)}
        }.navigationTitle("Moderation").task{await load()}
    }
    private func load()async{do{queue=try await session.api.request("/api/moderation/queue")}catch{self.error=error.localizedDescription}}
    private func decide(_ id:String,status:String)async{
        do{let payload=try session.api.encode(Decision(status:status));let _:ModerationItem=try await session.api.request("/api/moderation/videos/\(id)",method:"PATCH",json:payload);await load()}catch{self.error=error.localizedDescription}
    }
}
private struct Decision:Encodable{let status:String}
private struct ModerationItem:Decodable{let id:String;let status:String}
private struct ModerationQueue:Decodable{let videos:[ModerationVideo];let reports:[ModerationReport]}
private struct ModerationVideo:Decodable,Identifiable{let id:String;let caption:String;let videoUrl:String;let createdAt:String;let handle:String}
private struct ModerationReport:Decodable,Identifiable{let id:String;let targetType:String;let targetId:String;let reason:String;let createdAt:String}
