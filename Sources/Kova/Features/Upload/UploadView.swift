import SwiftUI
import PhotosUI
struct UploadView:View {
    @EnvironmentObject private var session:SessionStore
    @State private var selected:PhotosPickerItem?
    @State private var videoURL:URL?
    @State private var caption=""
    private var accountID: String { session.user?.id ?? "" }
    @State private var visibility="private"
    @State private var showCamera=false
    @State private var uploading=false
    @State private var message:String?
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    SectionHeading(title:"Create",subtitle:"Make something people will remember")
                    ZStack {
                        RoundedRectangle(cornerRadius:28).fill(KovaTheme.panel).frame(height:220)
                        VStack(spacing:15) {
                            Image(systemName:videoURL == nil ? "video.badge.plus" : "checkmark.circle.fill").font(.system(size:52)).foregroundStyle(KovaTheme.lavender)
                            Text(videoURL == nil ? "Your next story starts here" : "Video selected").font(.headline)
                            if let videoURL {Text(videoURL.lastPathComponent).font(.caption).foregroundStyle(KovaTheme.muted).lineLimit(1)}
                        }
                    }
                    HStack(spacing:12) {
                        PhotosPicker(selection:$selected,matching:.videos){Label("Choose video",systemImage:"photo.on.rectangle.angled").frame(maxWidth:.infinity)}.buttonStyle(.borderedProminent).tint(KovaTheme.accent)
                        Button{showCamera=true}label:{Label("Record",systemImage:"camera.fill").frame(maxWidth:.infinity)}.buttonStyle(.borderedProminent).tint(KovaTheme.accent)
                    }
                    VStack(alignment:.leading,spacing:9){Text("Caption").font(.headline);TextField("Tell your story...",text:$caption,axis:.vertical).lineLimit(3...6).padding(16).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:17))}
                    VStack(alignment:.leading,spacing:9){Text("Who can see this?").font(.headline);Picker("Visibility",selection:$visibility){Text("Everyone").tag("public");Text("Followers").tag("followers");Text("Only me").tag("private")}.pickerStyle(.segmented)}
                    GlassPanel {HStack(alignment:.top){Image(systemName:"checkmark.shield.fill").foregroundStyle(KovaTheme.aqua);Text("Videos publish as soon as uploading finishes. Follow community rules, respect privacy, and report unsafe posts. Staff can remove violations.").font(.footnote).foregroundStyle(KovaTheme.muted)}}
                    GradientButton(uploading ? "Publishing..." : "Publish video now",icon:"arrow.up.circle.fill") {Task{await publish()}}
                        .disabled(uploading || videoURL == nil || session.user == nil || !AppConfig.isConfigured)
                    if uploading {ProgressView("Uploading and publishing…").tint(KovaTheme.accent).frame(maxWidth:.infinity)}
                    if session.user==nil {Text("Sign in to upload.").font(.footnote).foregroundStyle(KovaTheme.muted)}
                    if let message {Text(message).font(.footnote).foregroundStyle(KovaTheme.lavender)}
                }.padding(18)
            }.background(KovaTheme.background)
            .onChange(of:selected){_,new in Task{if let movie=try? await new?.loadTransferable(type:PickedMovie.self){videoURL=movie.url}}}
            .task {
                if !accountID.isEmpty {
                    caption = KovaLocalState.draft(account: accountID, key: "video.caption")
                    let stored = KovaLocalState.draft(account: accountID, key: "video.visibility")
                    if ["public","followers","private"].contains(stored) { visibility = stored }
                }
            }
            .onChange(of:caption){_,new in
                if !accountID.isEmpty { KovaLocalState.setDraft(new, account: accountID, key:"video.caption") }
            }
            .onChange(of:visibility){_,new in
                if !accountID.isEmpty { KovaLocalState.setDraft(new, account: accountID, key:"video.visibility") }
            }
            .sheet(isPresented:$showCamera){CameraPicker{videoURL=$0}.ignoresSafeArea()}
        }
    }
    private func publish() async {
        guard let videoURL else{return}
        uploading=true;defer{uploading=false}
        do{let published=try await UploadService(api:session.api).upload(file:videoURL,caption:caption,visibility:visibility);message=published.message;self.videoURL=nil;caption="";selected=nil;visibility="private"}
        catch{message=error.localizedDescription}
    }
}
