import SwiftUI
struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) { self.title=title; self.icon=icon; self.action=action }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(KovaTheme.purpleGradient, in: RoundedRectangle(cornerRadius: 17))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}
