import SwiftUI
import AppKit

/// AMS Icon Library "keycap" drawing (a keyboard key), on a 24x24 grid scaled to the rect.
/// Stroke it with lineWidth ~1.9 * (size / 24), round caps and joins.
struct KeysIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let ox = rect.midX - 12 * s
        let oy = rect.midY - 12 * s
        var path = Path()
        path.addRoundedRect(in: CGRect(x: ox + 3.5 * s, y: oy + 4.5 * s, width: 17 * s, height: 15 * s),
                            cornerSize: CGSize(width: 3.5 * s, height: 3.5 * s))
        path.addRoundedRect(in: CGRect(x: ox + 7 * s, y: oy + 8 * s, width: 10 * s, height: 6.5 * s),
                            cornerSize: CGSize(width: 2 * s, height: 2 * s))
        return path
    }
}

/// 18x18 pt template image of the keycap drawing for the menu bar.
func keysMenuBarImage() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: true) { rect in
        let s = rect.width / 24
        let path = NSBezierPath(roundedRect: NSRect(x: 3.5 * s, y: 4.5 * s, width: 17 * s, height: 15 * s),
                                xRadius: 3.5 * s, yRadius: 3.5 * s)
        path.append(NSBezierPath(roundedRect: NSRect(x: 7 * s, y: 8 * s, width: 10 * s, height: 6.5 * s),
                                 xRadius: 2 * s, yRadius: 2 * s))
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        NSColor.black.setStroke()
        path.stroke()
        return true
    }
    image.isTemplate = true
    return image
}
