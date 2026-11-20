import SwiftUI
struct KovaAvatar: View {
    let name: String
    var size: CGFloat = 44
    var body: some View {
        ZStack {
            Circle().fill(KovaTheme.purpleGradient)
            Text(String(name.prefix(1)).uppercased()).font(.system(size:size*0.4,weight:.heavy,design:.rounded)).foregroundStyle(.white)
        }
        .frame(width:size,height:size)
        .overlay(Circle().stroke(.white.opacity(0.5),lineWidth:1.4))
        .accessibilityLabel(name)
    }
}
