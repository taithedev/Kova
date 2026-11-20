import SwiftUI

struct KovaAvatar: View {
    let name: String
    var size: CGFloat = 44
    var url: String? = nil
    private var preset: String? {
        guard let url, url.hasPrefix("kova-avatar:") else { return nil }
        return String(url.dropFirst("kova-avatar:".count))
    }
    private var presetColors: [Color] {
        switch preset {
        case "violet": return [Color(red: 0.62, green: 0.42, blue: 0.96), Color(red: 0.20, green: 0.12, blue: 0.50)]
        case "ocean": return [Color(red: 0.20, green: 0.65, blue: 0.98), Color(red: 0.07, green: 0.26, blue: 0.55)]
        case "sunset": return [Color(red: 1.0, green: 0.61, blue: 0.42), Color(red: 0.76, green: 0.19, blue: 0.34)]
        case "moss": return [Color(red: 0.26, green: 0.70, blue: 0.48), Color(red: 0.08, green: 0.29, blue: 0.27)]
        case "rose": return [Color(red: 0.99, green: 0.50, blue: 0.70), Color(red: 0.55, green: 0.12, blue: 0.39)]
        default: return [Color(white: 0.30), Color(white: 0.085)]
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(preset == nil ? KovaTheme.raised.gradient :
                    LinearGradient(colors: presetColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            if let url, let source = URL(string: url), source.scheme?.lowercased() == "https" {
                AsyncImage(url: source, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        initial
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(KovaTheme.background, lineWidth: size > 65 ? 4 : 2))
        .accessibilityLabel("Profile image for \(name)")
    }
    private var initial: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.39, weight: .black, design: .rounded))
            .foregroundStyle(preset == nil ? KovaTheme.foreground : .white)
    }
}
