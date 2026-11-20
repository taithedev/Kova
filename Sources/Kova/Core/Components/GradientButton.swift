import SwiftUI
struct GradientButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Text(title).font(.system(size: 16, weight: .bold))
                Spacer(minLength: 0)
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.black)
            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
