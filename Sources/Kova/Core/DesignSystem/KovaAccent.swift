import SwiftUI

/// Accent is limited to navigation, buttons, progress indicators and small
/// accents. Grayscale surfaces and authentic video/profile colors stay intact.
enum KovaAccent {
    static let options: [(name: String, key: String, color: Color)] = [
        ("Classic", "classic", .primary),
        ("Ocean", "ocean", Color(red: 0.12, green: 0.58, blue: 0.96)),
        ("Violet", "violet", Color(red: 0.60, green: 0.41, blue: 0.94)),
        ("Mint", "mint", Color(red: 0.18, green: 0.72, blue: 0.57)),
        ("Rose", "rose", Color(red: 0.93, green: 0.35, blue: 0.54)),
        ("Amber", "amber", Color(red: 0.94, green: 0.64, blue: 0.20)),
        ("Sky", "sky", Color(red: 0.31, green: 0.72, blue: 0.90))
    ]
    static func color(for key: String) -> Color {
        options.first { $0.key == key }?.color ?? .primary
    }
}
