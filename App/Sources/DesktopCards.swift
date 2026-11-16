import SwiftUI
import AppKit
import Combine
import ShortcutCore

/// The borderless window that sits on the desktop, behind all other windows.
final class DesktopPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class DesktopController {
    let panel = DesktopPanel()
    private let host: NSHostingView<CardStrip>
    private var bag = Set<AnyCancellable>()

    init(model: AppModel) {
        host = NSHostingView(rootView: CardStrip(model: model))
        host.setAccessibilityIdentifier("desktopCards")
        panel.contentView = host
        model.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in DispatchQueue.main.async { self?.refresh() } }
            .store(in: &bag)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &bag)
        refresh()
    }

    func refresh() {
        let model = AppModel.shared
        panel.appearance = model.look == "day" ? NSAppearance(named: .aqua)
            : model.look == "night" ? NSAppearance(named: .darkAqua) : nil
        guard model.showCards, !model.visibleGroups.isEmpty, let screen = NSScreen.main else {
            panel.orderOut(nil); return
        }
        host.layout()
        let size = host.fittingSize
        let area = screen.visibleFrame
        let width = min(size.width, area.width - 24)
        let frame = NSRect(x: area.midX - width / 2, y: area.minY + 14, width: width, height: size.height)
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    /// Writes a picture of the cards for checks.
    func snapshot(to url: URL) {
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}

// MARK: - The cards

struct CardStrip: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(model.visibleGroups) { group in
                AppCard(model: model, group: group)
            }
        }
        .padding(2)
        .fixedSize()
    }
}

struct AppCard: View {
    @ObservedObject var model: AppModel
    let group: AppGroup
    @Environment(\.colorScheme) private var scheme
    @State private var ticking: Set<UUID> = []

    var body: some View {
        let c = CardColours.of(group.colour, dark: scheme == .dark)
        let shown = Rules.visible(group, now: model.now)
        let rows = Array(shown.prefix(max(1, model.rowsPerCard)))
        let learned = Rules.learnedCount(group, now: model.now)

        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(group.name).font(.headline).foregroundStyle(c.title)
                Spacer(minLength: 8)
                if learned > 0 {
                    Text("\(learned) learned").font(.caption2).foregroundStyle(c.mark)
                }
                Button { AppDelegate.shared.openEditor(shortcut: nil, appName: group.name) } label: {
                    PlusMark().stroke(c.mark, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .frame(width: 10, height: 10).padding(3).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Add a shortcut for \(group.name)")
                .accessibilityIdentifier("cardAdd-\(group.name)")
            }
            .padding(.bottom, 2)

            ForEach(rows) { s in
                row(s, colours: c)
            }
            if shown.count > rows.count {
                Text("+\(shown.count - rows.count) more").font(.caption2).foregroundStyle(c.mark)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .frame(width: 260, alignment: .leading)
        .background(c.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityIdentifier("card-\(group.name)")
    }

    @ViewBuilder private func row(_ s: Shortcut, colours c: CardColours) -> some View {
        let recheck = model.status(s) == .recheck
        let done = ticking.contains(s.id)
        HStack(spacing: 6) {
            Button { tick(s) } label: {
                TickCircle(done: done, colour: c.mark).frame(width: 14, height: 14).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(recheck ? "Still know it? Tick to hide it for good" : "Tick when you know it")
            .accessibilityIdentifier("tick-\(s.name)")

            Text(s.name).font(.callout).foregroundStyle(c.text).lineLimit(1)
                .strikethrough(done, color: c.mark)
            if recheck {
                Text("Recheck").font(.caption2.weight(.medium)).foregroundStyle(c.fill)
                    .padding(.horizontal, 4).background(c.mark, in: Capsule())
            }
            Spacer(minLength: 6)
            KeyCaps(keys: s.keys, fill: c.key, text: c.keyText)
        }
        .contextMenu {
            Button("Change…") { AppDelegate.shared.openEditor(shortcut: s, appName: group.name) }
            if recheck { Button("Still learning") { model.bringBack(s.id) } }
            Button("I know it") { tick(s) }
        }
    }

    private func tick(_ s: Shortcut) {
        withAnimation(.easeOut(duration: 0.2)) { _ = ticking.insert(s.id) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            ticking.remove(s.id)
            model.tick(s.id)
        }
    }
}

struct KeyCaps: View {
    let keys: String
    let fill: Color
    let text: Color
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(Rules.keyParts(keys).enumerated()), id: \.offset) { _, part in
                Text(part)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(text)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .frame(minWidth: 18)
                    .background(fill, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
        .fixedSize()
    }
}

/// Empty circle; when ticked a hand-drawn check appears inside.
struct TickCircle: View {
    let done: Bool
    let colour: Color
    var body: some View {
        ZStack {
            Circle().stroke(colour, lineWidth: 1.5)
            if done {
                CheckMark().stroke(colour, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .padding(3.5)
            }
        }
    }
}

struct CheckMark: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + r.height * 0.05))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.38, y: r.maxY - r.height * 0.1))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.1))
        return p
    }
}

struct PlusMark: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        return p
    }
}
