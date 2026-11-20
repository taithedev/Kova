import SwiftUI
struct LoadingPanel: View {
    var label = "Loading"
    var body: some View { VStack(spacing:14) { ProgressView().tint(KovaTheme.lavender).scaleEffect(1.3); Text(label).foregroundStyle(KovaTheme.muted) }.frame(maxWidth:.infinity,maxHeight:.infinity) }
}
