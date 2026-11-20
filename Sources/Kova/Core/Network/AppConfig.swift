import Foundation

// The API's HTTPS origin is public configuration. Never place secrets in the app.
enum AppConfig {
    private static let preferenceKey = "kova.apiBaseURL"
    private static let placeholder = URL(string: "https://api.example.invalid")!

    static var apiBaseURL: URL {
        guard let saved = UserDefaults.standard.string(forKey: preferenceKey),
              let url = URL(string: saved), url.scheme?.lowercased() == "https"
        else { return placeholder }
        return url
    }

    static var isConfigured: Bool { apiBaseURL.host != placeholder.host }

    @discardableResult
    static func configure(_ input: String) -> Bool {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parts = URLComponents(string: value),
              parts.scheme?.lowercased() == "https",
              let host = parts.host, host.contains("."),
              parts.user == nil, parts.password == nil,
              parts.query == nil, parts.fragment == nil,
              parts.port == nil, parts.path.isEmpty || parts.path == "/"
        else { return false }
        UserDefaults.standard.set("https://" + host, forKey: preferenceKey)
        return true
    }
}
