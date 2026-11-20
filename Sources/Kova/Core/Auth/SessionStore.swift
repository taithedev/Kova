import Foundation
import SwiftUI
@MainActor final class SessionStore: ObservableObject {
    @Published private(set) var user: KovaUser?
    @Published var isPreviewing = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    private(set) var token: String?
    var api: APIClient { APIClient(token:token) }
    func restore() async {
        guard let previous=KeychainStore.read() else { return }
        token=previous
        do { user=try await api.request("/api/auth/me") }
        catch { token=nil; user=nil; KeychainStore.remove() }
    }
    func signIn(handle:String,password:String) async {
        isBusy=true; defer { isBusy=false }
        do {
            let payload=try api.encode(LoginPayload(handle:handle.lowercased(),password:password))
            let response:AuthResponse=try await api.request("/api/auth/login",method:"POST",json:payload)
            setSession(response)
        } catch { errorMessage=error.localizedDescription }
    }
    func register(handle:String,name:String,password:String,birthDate:String) async {
        isBusy=true; defer { isBusy=false }
        do {
            let payload=try api.encode(RegisterPayload(handle:handle.lowercased(),displayName:name,password:password,birthDate:birthDate))
            let response:AuthResponse=try await api.request("/api/auth/register",method:"POST",json:payload)
            setSession(response)
        } catch { errorMessage=error.localizedDescription }
    }
    private func setSession(_ auth:AuthResponse) { token=auth.token; user=auth.user; isPreviewing=false;KeychainStore.write(auth.token) }
    func updateUser(_ value:KovaUser) { user=value }
    func preview() { isPreviewing=true }
    func exitPreview() { isPreviewing=false }
    func signOut() async {
        if token != nil { let _:OkResponse?=try? await api.request("/api/auth/logout",method:"POST") }
        token=nil;user=nil;isPreviewing=false;KeychainStore.remove()
    }
}
struct LoginPayload:Encodable {let handle:String;let password:String}
struct RegisterPayload:Encodable {let handle:String;let displayName:String;let password:String;let birthDate:String}
struct OkResponse:Decodable {let ok:Bool}
