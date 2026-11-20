import Foundation
import SwiftUI
import UIKit

private struct KovaGitHubRelease: Decodable {
    let tagName: String
    let htmlUrl: URL
    let prerelease: Bool
    let draft: Bool
    let assets: [KovaReleaseAsset]
}
private struct KovaReleaseAsset: Decodable {
    let name: String
    let browserDownloadUrl: URL
}

/// Checks official public Kova releases; iOS will NOT permit an unsigned IPA
/// to self-install. A signed app must still be installed using an approved flow.
@MainActor final class KovaUpdateChecker: ObservableObject {
    @AppStorage("kova.checkForUpdates") var automaticChecks = true
    @Published private(set) var availableVersion: String?
    @Published private(set) var releaseURL: URL?
    @Published private(set) var updateFileURL: URL?
    @Published private(set) var isChecking = false
    @Published private(set) var message: String?
    private var lastCheck: Date?

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    func check(force: Bool = false) async {
        if !force && !automaticChecks { return }
        if !force, let lastCheck, Date().timeIntervalSince(lastCheck) < 7200 { return }
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        lastCheck = .now
        guard let url = URL(string: "https://api.github.com/repos/taithedev/Kova/releases/latest") else {
            return
        }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("Kova-iOS-UpdateChecker", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                message = "No published Kova release found. You can check the Releases page manually."
                return
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let release = try decoder.decode(KovaGitHubRelease.self, from: data)
            guard !release.prerelease, !release.draft else {
                message = "The latest release is still a preview."
                return
            }
            let latest = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let newer = compare(latest, to: currentVersion) > 0
            availableVersion = newer ? latest : nil
            releaseURL = newer ? release.htmlUrl : nil
            updateFileURL = release.assets.first(where: {
                $0.name.lowercased().hasSuffix(".ipa")
            })?.browserDownloadUrl
            message = newer ? "A new Kova release is available." :
                "You're using the latest published Kova release."
        } catch {
            message = "Update check unavailable. Your app still works normally."
        }
    }

    private func compare(_ lhs: String, to rhs: String) -> Int {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a != b { return a > b ? 1 : -1 }
        }
        return 0
    }

    func openRelease() {
        if let releaseURL {
            UIApplication.shared.open(releaseURL)
        } else if let url = URL(string: "https://github.com/taithedev/Kova/releases") {
            UIApplication.shared.open(url)
        }
    }
}
