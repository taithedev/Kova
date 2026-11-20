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
        ("Sky", "sky", Color(red: 0.31, green: 0.72, blue: 0.90)),
        ("Indigo", "indigo", Color(red: 0.36, green: 0.39, blue: 0.96)),
        ("Teal", "teal", Color(red: 0.12, green: 0.68, blue: 0.70)),
        ("Coral", "coral", Color(red: 0.96, green: 0.43, blue: 0.36)),
        ("Plum", "plum", Color(red: 0.71, green: 0.39, blue: 0.80)),
        ("Emerald", "emerald", Color(red: 0.18, green: 0.69, blue: 0.43)),
        ("Lime", "lime", Color(red: 0.64, green: 0.80, blue: 0.24)),
        ("Gold", "gold", Color(red: 0.90, green: 0.74, blue: 0.25)),
        ("Slate", "slate", Color(red: 0.43, green: 0.56, blue: 0.69))
    ]
    static func color(for key: String) -> Color {
        options.first { $0.key == key }?.color ?? .primary
    }
}
