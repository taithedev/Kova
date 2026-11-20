import Foundation

/// Device-local, account-scoped persistence. The access token remains in Keychain.
/// Draft files are protected by iOS and excluded from iCloud backups.
enum KovaLocalState {
    private static func directory() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                                    in: .userDomainMask).first else { return nil }
        let directory = base.appendingPathComponent("KovaLocal", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var target = directory
            try target.setResourceValues(resourceValues)
            return directory
        } catch { return nil }
    }

    private static func file(_ name: String) -> URL? {
        directory()?.appendingPathComponent(name, isDirectory: false)
    }

    private static func write(_ data: Data, to url: URL) {
        do {
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
        } catch {
            // An unavailable local disk must never prevent using Kova.
        }
    }

    static func storeUser(_ user: KovaUser) {
        guard let url = file("signed-user.json"),
              let data = try? JSONEncoder().encode(user) else { return }
        write(data, to: url)
    }

    static func cachedUser() -> KovaUser? {
        guard let url = file("signed-user.json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(KovaUser.self, from: data)
    }

    static func clearUser() {
        if let url = file("signed-user.json") { try? FileManager.default.removeItem(at: url) }
    }

    private static func draftFile(for account: String) -> URL? {
        let safe = account.replacingOccurrences(
            of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression
        )
        return file("drafts-" + safe + ".json")
    }

    private static func draftMap(account: String) -> [String: String] {
        guard let url = draftFile(for: account),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return map
    }

    static func draft(account: String, key: String) -> String {
        draftMap(account: account)[key] ?? ""
    }

    static func setDraft(_ value: String, account: String, key: String) {
        guard let url = draftFile(for: account) else { return }
        var map = draftMap(account: account)
        if value.isEmpty { map.removeValue(forKey: key) }
        else { map[key] = String(value.prefix(2200)) }
        guard let data = try? JSONEncoder().encode(map) else { return }
        write(data, to: url)
    }

    static func clearDrafts(account: String) {
        if let url = draftFile(for: account) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
