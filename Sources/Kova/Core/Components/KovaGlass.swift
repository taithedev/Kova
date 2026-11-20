import SwiftUI

struct KovaGlassSurface: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(KovaTheme.border, lineWidth: 1))
        }
    }
}
extension View {
    func kovaGlass(radius: CGFloat = 22) -> some View {
        modifier(KovaGlassSurface(radius: radius))
    }
}
