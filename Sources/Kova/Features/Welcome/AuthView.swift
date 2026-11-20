import SwiftUI

private struct AccountAvailability: Decodable {
    let available: Bool
    let reason: String?
}
struct AuthView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var signUp = false
    @State private var handle = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var showPassword = false
    @State private var showConfirm = false
    @State private var birthDate = Date.now
    @State private var selectedBirthday = false
    @State private var available: Bool?
    @State private var checking = false

    private var normalized: String { handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    private var validHandle: Bool { normalized.range(of: "^[a-z0-9_]{3,25}$", options: .regularExpression) != nil }
    private var validPassword: Bool { password.count >= 10 && password.count <= 128 }
    private var age: Int { Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0 }
    private var canSubmit: Bool {
        validHandle && !session.isBusy && !password.isEmpty &&
        (!signUp || (validPassword && confirm == password && selectedBirthday && age >= 13 && available != false))
    }
    private var birthdayISO: String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: birthDate)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    KovaMark(size: 48).padding(.top, 10)
                    Text(signUp ? "Make your\naccount." : "Welcome\nback.")
                        .font(.system(size: 43, weight: .black))
                        .tracking(-2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(signUp ? "One username. One password. That's Kova." : "Sign in to your Kova account.")
                        .font(.system(size: 15))
                        .foregroundStyle(KovaTheme.muted)
                    usernameField
                    passwordField
                    if signUp {
                        confirmationField
                        ageField
                    }
                    GradientButton(signUp ? "Create account" : "Sign in", icon: "arrow.right") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    if session.isBusy { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                    Button(signUp ? "Already have an account? Sign in" : "New to Kova? Create an account") {
                        signUp.toggle()
                        confirm = ""
                        available = nil
                        session.errorMessage = nil
                    }
                    .foregroundStyle(KovaTheme.foreground)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    Text("Kova accounts are for ages 13+. Teen accounts stay private, and direct messaging is disabled.")
                        .foregroundStyle(KovaTheme.muted)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
                .padding(.bottom, 35)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(KovaTheme.background)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .task(id: normalized) { await checkUsername() }
            .onChange(of: signUp) { _, new in
                if new { Task { await checkUsername() } }
            }
            .alert("Kova", isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.errorMessage = nil } }
            )) { Button("OK", role: .cancel) { session.errorMessage = nil } }
            message: { Text(session.errorMessage ?? "") }
        }
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Username")
            HStack {
                Text("@").foregroundStyle(KovaTheme.muted)
                TextField("username", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
            }
            .padding(15)
            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
            if signUp && !normalized.isEmpty {
                if !validHandle { hint("Use 3–25 lowercase letters, numbers or underscores.", symbol: "info.circle") }
                else if checking { hint("Checking username...", symbol: "clock") }
                else if let available {
                    hint(available ? "Username is available." : "Username is already taken.",
                         symbol: available ? "checkmark.circle" : "xmark.circle")
                }
            }
        }
    }
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Password")
            HStack(spacing: 8) {
                Group {
                    if showPassword { TextField("Password", text: $password) }
                    else { SecureField("Password", text: $password) }
                }
                .textContentType(signUp ? .newPassword : .password)
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(KovaTheme.muted)
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
            .padding(15)
            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
            if signUp { hint(validPassword ? "Password length looks good." : "Use at least 10 characters.", symbol: validPassword ? "checkmark.circle" : "lock") }
        }
    }
    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Confirm password")
            HStack {
                Group {
                    if showConfirm { TextField("Confirm password", text: $confirm) }
                    else { SecureField("Confirm password", text: $confirm) }
                }
                .textContentType(.newPassword)
                Button { showConfirm.toggle() } label: {
                    Image(systemName: showConfirm ? "eye.slash" : "eye")
                        .foregroundStyle(KovaTheme.muted)
                }
            }
            .padding(15)
            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
            if !confirm.isEmpty && confirm != password { hint("Passwords don't match.", symbol: "exclamationmark.circle") }
        }
    }
    private var ageField: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Date of birth · age eligibility")
            DatePicker("Birthday", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.white)
                .onChange(of: birthDate) { _, _ in selectedBirthday = true }
            if selectedBirthday && age < 13 {
                hint("Kova accounts currently require age 13 or older.", symbol: "info.circle")
            }
        }
    }
    private func label(_ name: String) -> some View {
        Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(KovaTheme.muted)
    }
    private func hint(_ message: String, symbol: String) -> some View {
        Label(message, systemImage: symbol)
            .font(.system(size: 12))
            .foregroundStyle(KovaTheme.muted)
    }
    private func checkUsername() async {
        guard signUp, validHandle else {
            available = nil
            checking = false
            return
        }
        checking = true
        defer { checking = false }
        try? await Task.sleep(for: .milliseconds(370))
        if Task.isCancelled { return }
        let encoded = normalized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? normalized
        do {
            let result: AccountAvailability = try await session.api.request("/api/auth/username-available?handle=\(encoded)")
            if !Task.isCancelled { available = result.available }
        } catch { available = nil }
    }
    private func submit() async {
        guard canSubmit else { return }
        if signUp {
            await session.register(handle: normalized, name: normalized, password: password, birthDate: birthdayISO)
        } else {
            await session.signIn(handle: normalized, password: password)
        }
        if session.user != nil { dismiss() }
    }
}
