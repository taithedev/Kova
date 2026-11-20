import Foundation

/// Fixed, public Kova API. Users never enter a URL or database credential.
enum AppConfig {
    static let apiBaseURL = URL(string: "https://br-autumn-water-bc3ti0gm-kovaapi.compute.c-16.us-east-1.aws.neon.tech")!
    static let isConfigured = true
}
