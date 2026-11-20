import SwiftUI
struct AuthView:View {
    @EnvironmentObject private var session:SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var signUp=false
    @State private var handle=""
    @State private var displayName=""
    @State private var password=""
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
                    if !AppConfig.isConfigured {
                        Label("Connect an API deployment in AppConfig.swift before registering.",systemImage:"network.slash").font(.footnote).foregroundStyle(.orange)
                    }
                    GradientButton(signUp ? "Create account" : "Sign in",icon:"arrow.right") {
                        Task {
                            if signUp {await session.register(handle:handle,name:displayName,password:password,birthDate:dateFormat.string(from:birthDate))}
                            else {await session.signIn(handle:handle,password:password)}
                            if session.user != nil {dismiss()}
                        }
                    }.disabled(session.isBusy || !AppConfig.isConfigured)
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
