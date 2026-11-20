import SwiftUI
struct FollowRequestsView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var requests:[FollowRequest]=[]
    @State private var status:String?
    var body:some View {
        List {
            if requests.isEmpty {Text("No pending follow requests.").foregroundStyle(.secondary)}
            ForEach(requests){r in HStack{KovaAvatar(name:r.displayName);VStack(alignment:.leading){Text(r.displayName);Text("@"+r.handle).font(.caption).foregroundStyle(.secondary)};Spacer();Button("Accept"){Task{await accept(r)}}.buttonStyle(.borderedProminent)}}
            if let status {Text(status)}
        }.navigationTitle("Follow requests").task{await load()}
    }
    private func load()async{if let result:FollowRequestPage=try? await session.api.request("/api/follows/requests"){requests=result.items}}
    private func accept(_ r:FollowRequest) async {do{let _:FollowStatus=try await session.api.request("/api/follows/requests/\(r.id)",method:"POST");await load()}catch{status=error.localizedDescription}}
}
struct FollowRequest:Decodable,Identifiable{let id:String;let handle:String;let displayName:String;let createdAt:String}
struct FollowRequestPage:Decodable{let items:[FollowRequest]}
struct FollowStatus:Decodable{let status:String}
