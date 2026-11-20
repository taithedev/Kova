import SwiftUI
import UIKit

/// Black/white controls; creator media and profile banners keep their color.
enum KovaTheme {
    static var accent: Color { KovaAccent.color(for: UserDefaults.standard.string(forKey: "kova.accent") ?? "classic") }
    static var appearance: String { UserDefaults.standard.string(forKey: "kova.appearance") ?? "dark" }
    private static func adaptive(_ light: UIColor, _ dark: UIColor, oled: UIColor? = nil) -> Color {
        let mode = appearance
        return Color(uiColor: UIColor { traits in
            let darkMode = mode == "system" ? traits.userInterfaceStyle == .dark : mode != "light"
            if darkMode && mode == "oled" { return oled ?? dark }
            return darkMode ? dark : light
        })
    }
    static var background: Color { adaptive(.white, UIColor(red: 0.055, green: 0.055, blue: 0.064, alpha: 1), oled: .black) }
    static var panel: Color { adaptive(UIColor(white: 0.957, alpha: 1), UIColor(white: 0.12, alpha: 1), oled: UIColor(white: 0.07, alpha: 1)) }
    static var raised: Color { adaptive(UIColor(white: 0.91, alpha: 1), UIColor(white: 0.19, alpha: 1), oled: UIColor(white: 0.14, alpha: 1)) }
    static var border: Color { adaptive(UIColor.black.withAlphaComponent(0.09), UIColor.white.withAlphaComponent(0.14)) }
    static var muted: Color { adaptive(UIColor(white: 0.39, alpha: 1), UIColor(white: 0.66, alpha: 1)) }
    static var foreground: Color { adaptive(.black, .white) }
    static var inverted: Color { adaptive(.white, .black) }
    static var lavender: Color { foreground }
    static var aqua: Color { foreground }
    static var purpleGradient: LinearGradient {
        LinearGradient(colors: [foreground, foreground.opacity(0.79)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var videoGradients: [[Color]] = [
        [Color(red: 0.13, green: 0.20, blue: 0.42), Color(red: 0.03, green: 0.07, blue: 0.17)],
        [Color(red: 0.36, green: 0.16, blue: 0.24), Color(red: 0.10, green: 0.04, blue: 0.12)],
        [Color(red: 0.08, green: 0.32, blue: 0.32), Color(red: 0.02, green: 0.10, blue: 0.16)]
    ]
    static func banner(_ id: String) -> LinearGradient {
        let shades: [Color]
        switch id {
        case "glacier": shades = [Color(red: 0.21, green: 0.59, blue: 0.96), Color(red: 0.30, green: 0.26, blue: 0.74)]
        case "orchid": shades = [Color(red: 0.62, green: 0.29, blue: 0.78), Color(red: 0.20, green: 0.13, blue: 0.47)]
        case "coral": shades = [Color(red: 0.96, green: 0.38, blue: 0.39), Color(red: 0.66, green: 0.18, blue: 0.34)]
        case "mint": shades = [Color(red: 0.16, green: 0.68, blue: 0.56), Color(red: 0.03, green: 0.25, blue: 0.33)]
        case "sunset": shades = [Color(red: 0.98, green: 0.65, blue: 0.32), Color(red: 0.77, green: 0.29, blue: 0.43)]
        default: shades = [Color(white: 0.28), Color(white: 0.035)]
        }
        return LinearGradient(colors: shades, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
