import SwiftUI

/// Hand-drawn K mark, deliberately geometric rather than illustrative.
struct KovaMark: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous).fill(.black)
            GeometryReader { geometry in
                let s = min(geometry.size.width, geometry.size.height)
                Path { path in
                    path.move(to: CGPoint(x: s * 0.29, y: s * 0.25))
                    path.addLine(to: CGPoint(x: s * 0.29, y: s * 0.75))
                    path.move(to: CGPoint(x: s * 0.67, y: s * 0.26))
                    path.addLine(to: CGPoint(x: s * 0.395, y: s * 0.51))
                    path.addLine(to: CGPoint(x: s * 0.69, y: s * 0.75))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: s * 0.093, lineCap: .round, lineJoin: .round))
            }
            .padding(size * 0.025)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Kova")
    }
}
