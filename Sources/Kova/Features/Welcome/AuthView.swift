import SwiftUI
struct AuthView:View {
    @EnvironmentObject private var session:SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var signUp=false
    @State private var handle=""
    @State private var displayName=""
    @State private var password=""
    @State private var serverURL=""
    @State private var serverMessage:String?
    @State private var hasServer=AppConfig.isConfigured
    @State private var birthDate=Date.now
    private var dateFormat:DateFormatter { let f=DateFormatter(); f.dateFormat="yyyy-MM-dd";f.timeZone=TimeZone(secondsFromGMT:0);return f }
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:17) {
                    Text(signUp ? "Join Kova" : "Welcome back").font(.kovaDisplay)
                    Text("A place to create and discover.").foregroundStyle(KovaTheme.muted)
                    labeledField("Username") {TextField("your_handle",text:$handle).textInputAutocapitalization(.never).autocorrectionDisabled()}
                    if signUp {
                        labeledField("Display name"){TextField("Your name",text:$displayName)}
                        VStack(alignment:.leading,spacing:8){Text("Date of birth").font(.footnote).foregroundStyle(KovaTheme.muted);DatePicker("Birthday",selection:$birthDate,in:...Date.now,displayedComponents:.date).datePickerStyle(.compact)}
                    }
                    labeledField("Password") {SecureField("At least 10 characters",text:$password)}
                    if !hasServer {
                        VStack(alignment:.leading,spacing:9) {
                            Label("Connect your Kova API",systemImage:"network")
                                .font(.system(size:14,weight:.semibold))
                            TextField("https://your-kova-api.vercel.app",text:$serverURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .padding(13)
                                .background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:12))
                            Button("Save HTTPS server") {
                                hasServer=AppConfig.configure(serverURL)
                                serverMessage=hasServer ? "Saved. Sign in to continue." : "Enter a valid HTTPS root URL."
                            }
                            .font(.system(size:14,weight:.bold)).foregroundStyle(.white)
                            if let serverMessage {
                                Text(serverMessage).font(.caption).foregroundStyle(KovaTheme.muted)
                            }
                        }
                    } else {
                        Label("API: " + (AppConfig.apiBaseURL.host ?? "Connected"),
                              systemImage:"checkmark.circle")
                            .font(.caption).foregroundStyle(KovaTheme.muted)
                    }
                    GradientButton(signUp ? "Create account" : "Sign in",icon:"arrow.right") {
                        Task {
                            if signUp {await session.register(handle:handle,name:displayName,password:password,birthDate:dateFormat.string(from:birthDate))}
                            else {await session.signIn(handle:handle,password:password)}
                            if session.user != nil {dismiss()}
                        }
                    }.disabled(session.isBusy || !hasServer)
                    if session.isBusy {ProgressView().frame(maxWidth:.infinity)}
                    Button(signUp ? "Already have an account? Sign in" : "New here? Create an account") {signUp.toggle()}
                        .frame(maxWidth:.infinity).foregroundStyle(KovaTheme.lavender).padding(.top,5)
                    Text("Minimum age 13. Accounts for ages 13–17 start private, with direct messages disabled.").font(.footnote).foregroundStyle(KovaTheme.muted)
                }.padding(24)
            }
            .background(KovaTheme.background)
            .toolbar{ToolbarItem(placement:.topBarTrailing){Button("Close"){dismiss()}}}
            .alert("Kova",isPresented:Binding(get:{session.errorMessage != nil},set:{if !$0 {session.errorMessage=nil}})) {Button("OK",role:.cancel){session.errorMessage=nil}} message:{Text(session.errorMessage ?? "")}
        }
    }
    private func labeledField<C:View>(_ title:String,@ViewBuilder content:()->C)->some View {
        VStack(alignment:.leading,spacing:8){Text(title).font(.footnote).foregroundStyle(KovaTheme.muted);content().padding(14).background(KovaTheme.panel,in:RoundedRectangle(cornerRadius:14))}
    }
}
