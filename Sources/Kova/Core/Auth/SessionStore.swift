import Foundation
import SwiftUI

@MainActor final class SessionStore: ObservableObject {
    @Published private(set) var user: KovaUser?
    @Published private(set) var isRestoring = true
    @Published var isPreviewing = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published private(set) var hasVerifiedSession = false
    private var hasStartedRestore = false
    private var lastProfileRefresh: Date?
    private(set) var token: String?
    var api: APIClient { APIClient(token: token) }

    func restore() async {
        guard !hasStartedRestore else { return }
        hasStartedRestore = true
        defer { isRestoring = false }
        guard let previous = KeychainStore.read() else {
            KovaLocalState.clearUser()
            return
        }
        token = previous
        if let cached = KovaLocalState.cachedUser() {
            user = cached
            isRestoring = false
        }
        do {
            let fresh: KovaUser = try await api.request("/api/auth/me")
            guard token == previous else { return }
            user = fresh
            hasVerifiedSession = true
            lastProfileRefresh = .now
            KovaLocalState.storeUser(fresh)
        } catch APIError.unauthorized {
            guard token == previous else { return }
            token = nil
            user = nil
            hasVerifiedSession = false
            KeychainStore.remove()
            KovaLocalState.clearUser()
        } catch {
            // Preserve the remembered account and navigation during temporary outages.
            errorMessage = error.localizedDescription
        }
    }

    /// Refresh quietly after foregrounding instead of resetting the entire app.
    func refreshIfNeeded() async {
        guard token != nil, user != nil, !isRestoring else { return }
        if let lastProfileRefresh, Date().timeIntervalSince(lastProfileRefresh) < 300 { return }
        guard let expected = token else { return }
        do {
            let fresh: KovaUser = try await api.request("/api/auth/me")
            guard token == expected else { return }
            updateUser(fresh)
            hasVerifiedSession = true
            lastProfileRefresh = .now
        } catch APIError.unauthorized {
            guard token == expected else { return }
            await clearSession()
        } catch {
            // Background connectivity changes never eject users from a live tab.
        }
    }

    func signIn(handle: String, password: String) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let payload = try api.encode(LoginPayload(handle: handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), password: password))
            let response: AuthResponse = try await api.request("/api/auth/login", method: "POST", json: payload)
            setSession(response)
        } catch { errorMessage = error.localizedDescription }
    }

    func register(handle: String, name: String, password: String, birthDate: String) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let cleaned = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let payload = try api.encode(RegisterPayload(handle: cleaned, displayName: name.isEmpty ? cleaned : name, password: password, birthDate: birthDate))
            let response: AuthResponse = try await api.request("/api/auth/register", method: "POST", json: payload)
            setSession(response)
        } catch { errorMessage = error.localizedDescription }
    }

    private func setSession(_ auth: AuthResponse) {
        token = auth.token
        user = auth.user
        hasVerifiedSession = true
        lastProfileRefresh = .now
        KovaLocalState.storeUser(auth.user)
        isPreviewing = false
        errorMessage = nil
        KeychainStore.write(auth.token)
    }
    func updateUser(_ value: KovaUser) {
        user = value
        KovaLocalState.storeUser(value)
    }
    func preview() { isPreviewing = true }
    func exitPreview() { isPreviewing = false }
    func signOut() async {
        if token != nil { let _: OkResponse? = try? await api.request("/api/auth/logout", method: "POST") }
        await clearSession()
    }
    private func clearSession() async {
        token = nil
        user = nil
        hasVerifiedSession = false
        lastProfileRefresh = nil
        isPreviewing = false
        errorMessage = nil
        KeychainStore.remove()
        KovaLocalState.clearUser()
        // Drafts remain local for the same account and cannot cross accounts.
    }

}

struct LoginPayload: Encodable { let handle: String; let password: String }
struct RegisterPayload: Encodable { let handle: String; let displayName: String; let password: String; let birthDate: String }
struct OkResponse: Decodable { let ok: Bool }
