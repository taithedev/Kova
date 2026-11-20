import SwiftUI

struct KovaAvatar: View {
    let name: String
    var size: CGFloat = 44
    var url: String? = nil

    var body: some View {
        ZStack {
            Circle().fill(KovaTheme.raised)
            if let url, let source = URL(string: url), source.scheme == "https" {
                AsyncImage(url: source, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { state in
                    switch state {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
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
            .foregroundStyle(KovaTheme.foreground)
    }
}
