import SwiftUI
struct ReportSheet:View {
    @EnvironmentObject private var session:SessionStore
    @Environment(\.dismiss) private var dismiss
    let targetType:String
    let targetID:String
    @State private var reason="bullying"
    @State private var detail=""
    @State private var status=""
    private let reasons=[("bullying","Bullying or harassment"),("sexual_content","Sexual content"),("violence","Violence"),("hate","Hate or discrimination"),("spam","Spam or scams"),("privacy","Privacy concerns"),("other","Other")]
    var body:some View {
        NavigationStack {
            Form {
                Section("Why are you reporting this?"){Picker("Reason",selection:$reason){ForEach(reasons,id:\.0){item in Text(item.1).tag(item.0)}}}
                Section("Additional details") {TextField("Optional context",text:$detail,axis:.vertical).lineLimit(3...6)}
                Section {Button("Submit report") {Task{await submit()}}.disabled(session.user == nil)}
                Text("Reports go to Kova moderators. In an emergency, contact trusted local help; this form is not an emergency service.").font(.caption).foregroundStyle(.secondary)
                if !status.isEmpty {Text(status).foregroundStyle(KovaTheme.lavender)}
            }
            .navigationTitle("Report content")
            .toolbar{ToolbarItem(placement:.topBarTrailing){Button("Done"){dismiss()}}}
        }
    }
    private func submit() async {
        do {let payload=try session.api.encode(ReportPayload(targetType:targetType,targetId:targetID,reason:reason,detail:detail));let _:SubmittedReport=try await session.api.request("/api/reports",method:"POST",json:payload);status="Report sent. Thank you."}
        catch{status=error.localizedDescription}
    }
}
private struct ReportPayload:Encodable{let targetType:String;let targetId:String;let reason:String;let detail:String}
private struct SubmittedReport:Decodable{let id:String;let status:String}
