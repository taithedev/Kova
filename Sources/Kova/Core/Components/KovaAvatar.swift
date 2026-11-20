import SwiftUI
struct KovaAvatar: View {
    let name: String
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(KovaTheme.raised)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(KovaTheme.border, lineWidth: 1))
        .accessibilityLabel(name)
    }
}
