import SwiftUI
struct EmptyState: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName:icon).font(.system(size:48,weight:.thin)).foregroundStyle(KovaTheme.lavender)
            Text(title).font(.kovaHeadline).multilineTextAlignment(.center)
            Text(detail).foregroundStyle(KovaTheme.muted).font(.subheadline).multilineTextAlignment(.center).padding(.horizontal,30)
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity).padding(30)
    }
}
