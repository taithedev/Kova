import SwiftUI

struct KovaVerifiedBadge: View {
    var size: CGFloat = 17
    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, Color(red: 0.14, green: 0.57, blue: 0.99))
            .font(.system(size: size, weight: .semibold))
            .accessibilityLabel("Verified account")
    }
}
struct KovaRoleBadge: View {
    let role: String?
    private var title: String {
        switch role {
        case "owner": return "OWNER"
        case "admin": return "ADMIN"
        case "moderator": return "STAFF"
        case "developer": return "DEVELOPER"
        default: return ""
        }
    }
    var body: some View {
        if !title.isEmpty {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(KovaTheme.foreground)
                .background(KovaTheme.raised, in: Capsule())
        }
    }
}
