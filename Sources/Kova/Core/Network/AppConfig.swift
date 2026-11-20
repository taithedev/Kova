import Foundation
// Public endpoint only. Put credentials in backend/.env.local, NEVER in this file.
enum AppConfig {
    static let apiBaseURL = URL(string: "https://REPLACE_WITH_YOUR_KOVA_API.vercel.app")!
    static var isConfigured: Bool { apiBaseURL.host != "replace_with_your_kova_api.vercel.app" }
}
