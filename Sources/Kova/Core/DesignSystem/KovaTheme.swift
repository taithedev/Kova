import SwiftUI
struct KovaTheme {
    static let background = Color(red: 0.035, green: 0.039, blue: 0.07)
    static let panel = Color(red: 0.086, green: 0.090, blue: 0.14)
    static let lavender = Color(red: 0.71, green: 0.59, blue: 1.0)
    static let aqua = Color(red: 0.39, green: 0.88, blue: 0.96)
    static let muted = Color(red: 0.62, green: 0.63, blue: 0.72)
    static let purpleGradient = LinearGradient(colors: [lavender, Color(red: 0.46, green: 0.38, blue: 0.94)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let videoGradients: [[Color]] = [
        [Color(red:0.39,green:0.22,blue:0.69),Color(red:0.10,green:0.05,blue:0.20)],
        [Color(red:0.11,green:0.38,blue:0.47),Color(red:0.04,green:0.08,blue:0.21)],
        [Color(red:0.51,green:0.17,blue:0.35),Color(red:0.12,green:0.05,blue:0.17)]
    ]
}
