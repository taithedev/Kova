import SwiftUI

struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title).font(.system(size: 16, weight: .bold))
                Spacer(minLength: 0)
                if let icon {
                    Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 21)
            .frame(maxWidth: .infinity, minHeight: 53)
            .foregroundStyle(KovaTheme.inverted)
            .background(KovaTheme.foreground, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
