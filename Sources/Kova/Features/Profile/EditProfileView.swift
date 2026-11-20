import SwiftUI
struct EditProfileView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var displayName=""
    @State private var bio=""
    @State private var isPrivate=true
    @State private var message:String?
    var body:some View {
        Form {
            Section("Profile") {TextField("Display name",text:$displayName);TextField("Bio",text:$bio,axis:.vertical).lineLimit(2...5)}
            Section("Privacy") {Toggle("Private account",isOn:$isPrivate);Text("Private accounts require approval for new followers.").font(.footnote).foregroundStyle(.secondary)}
            Section{Button("Save changes"){Task{await save()}}}
            if let message {Text(message)}
        }.navigationTitle("Edit profile")
            .onAppear{displayName=session.user?.displayName ?? "";bio=session.user?.bio ?? "";isPrivate=session.user?.isPrivate ?? true}
    }
    private func save() async {
        do{
            let payload=try session.api.encode(EditPayload(displayName:displayName,bio:bio,isPrivate:isPrivate))
            let result:KovaUser=try await session.api.request("/api/users/me",method:"PATCH",json:payload)
            session.updateUser(result);message="Changes saved."
        }catch{message=error.localizedDescription}
    }
}
private struct EditPayload:Encodable{let displayName:String;let bio:String;let isPrivate:Bool}
