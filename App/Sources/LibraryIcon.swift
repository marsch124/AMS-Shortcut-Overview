import SwiftUI
import AppKit

/// AMS Icon Library "keys" drawing, on a 24x24 grid scaled to the rect.
/// Stroke it with lineWidth ~1.9 * (size / 24), round caps and joins.
struct KeysIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let ox = rect.midX - 12 * s
        let oy = rect.midY - 12 * s
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        path.addEllipse(in: CGRect(x: ox + 3.5 * s, y: oy + 4 * s, width: 9 * s, height: 9 * s))
        path.move(to: p(11.2, 11.7)); path.addLine(to: p(20, 20.5))
        path.move(to: p(17.5, 18)); path.addLine(to: p(19.5, 16))
        path.move(to: p(15, 15.5)); path.addLine(to: p(16.7, 13.8))
        return path
    }
}

/// 18x18 pt template image of the keys drawing for the menu bar.
func keysMenuBarImage() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: true) { rect in
        let s = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
        let path = NSBezierPath()
        path.appendOval(in: NSRect(x: 3.5 * s, y: 4 * s, width: 9 * s, height: 9 * s))
        path.move(to: p(11.2, 11.7)); path.line(to: p(20, 20.5))
        path.move(to: p(17.5, 18)); path.line(to: p(19.5, 16))
        path.move(to: p(15, 15.5)); path.line(to: p(16.7, 13.8))
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
