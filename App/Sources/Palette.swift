import SwiftUI
import AppKit

/// Each app's colour, by day and by night.
struct CardColours {
    let fill: Color      // card background
    let title: Color     // app name
    let text: Color      // shortcut names
    let mark: Color      // tick circle, buttons
    let key: Color       // keycap background
    let keyText: Color

    static let all: [String: (light: [UInt32], dark: [UInt32])] = [
        // light: fill, title, text, mark ; dark: fill, title, text, mark
        "purple": ([0xEEEDFE, 0x3C3489, 0x26215C, 0x534AB7], [0x3C3489, 0xCECBF6, 0xEEEDFE, 0xAFA9EC]),
        "coral":  ([0xFAECE7, 0x712B13, 0x4A1B0C, 0x993C1D], [0x712B13, 0xF5C4B3, 0xFAECE7, 0xF0997B]),
        "teal":   ([0xE1F5EE, 0x085041, 0x04342C, 0x0F6E56], [0x085041, 0x9FE1CB, 0xE1F5EE, 0x5DCAA5]),
        "blue":   ([0xE6F1FB, 0x0C447C, 0x042C53, 0x185FA5], [0x0C447C, 0xB5D4F4, 0xE6F1FB, 0x85B7EB]),
        "pink":   ([0xFBEAF0, 0x72243E, 0x4B1528, 0x993556], [0x72243E, 0xF4C0D1, 0xFBEAF0, 0xED93B1]),
        "amber":  ([0xFAEEDA, 0x633806, 0x412402, 0x854F0B], [0x633806, 0xFAC775, 0xFAEEDA, 0xEF9F27]),
        "green":  ([0xEAF3DE, 0x27500A, 0x173404, 0x3B6D11], [0x27500A, 0xC0DD97, 0xEAF3DE, 0x97C459]),
    ]

    static let names = ["purple", "coral", "teal", "blue", "pink", "amber", "green"]

    static func of(_ name: String, dark: Bool) -> CardColours {
        let pair = all[name] ?? all["purple"]!
        let v = dark ? pair.dark : pair.light
        return CardColours(
            fill: Color(hex: v[0]), title: Color(hex: v[1]), text: Color(hex: v[2]), mark: Color(hex: v[3]),
            key: dark ? Color.black.opacity(0.28) : Color.white,
            keyText: dark ? Color(hex: v[2]) : Color(hex: v[1]))
    }

    /// Full colour for the main button, the same by day and by night (white text stays readable).
    static func button(_ name: String) -> Color {
        Color(hex: (all[name] ?? all["purple"]!).light[3])
    }

    /// The strong colour for headings and marks in windows (readable on both).
    static func accent(_ name: String) -> Color {
        Color(nsColor: NSColor(name: nil) { app in
            let pair = all[name] ?? all["purple"]!
            let dark = app.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: dark ? pair.dark[3] : pair.light[3])
        })
    }
}

extension Color {
    init(hex: UInt32) { self.init(nsColor: NSColor(hex: hex)) }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
