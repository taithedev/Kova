import SwiftUI

struct GlassPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .background(KovaTheme.panel.opacity(0.74), in: RoundedRectangle(cornerRadius: 21))
            .kovaGlass(radius: 21)
    }
}
