import SwiftUI

/// Kova's interface is strictly achromatic. Uploaded video is NEVER color-filtered.
enum KovaTheme {
    static let background = Color.black
    static let panel = Color(red: 0.075, green: 0.075, blue: 0.075)
    static let raised = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let border = Color.white.opacity(0.13)
    static let muted = Color(red: 0.64, green: 0.64, blue: 0.64)
    static let foreground = Color.white
    // Compatibility names used throughout the original codebase; now monochrome.
    static let lavender = Color.white
    static let aqua = Color.white
    static let purpleGradient = LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
    static let videoGradients: [[Color]] = [
        [Color(white:0.17), .black],
        [Color(white:0.27), Color(white:0.07)],
        [Color(white:0.12), Color(white:0.03)]
    ]
}
