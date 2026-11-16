import SwiftUI
import AppKit
import ServiceManagement
import ShortcutCore

@main
struct AMSShortcutOverviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static private(set) var shared: AppDelegate!
    let model = AppModel.shared
    var desktop: DesktopController?
    private var statusItem: NSStatusItem!
    private var manageWindow: NSWindow?
    private var editorWindow: NSWindow?

    override init() { super.init(); AppDelegate.shared = self }

    func applicationDidFinishLaunching(_ note: Notification) {
        // A saved place in the menu bar (pt from the right edge): between Mic Check (177) and
        // Deck Mate (266), right of Tidy Bar's line, so it always shows and never sits behind the notch.
        let placeKey = "NSStatusItem Preferred Position shortcutOverview"
        if UserDefaults.standard.object(forKey: placeKey) == nil { UserDefaults.standard.set(222, forKey: placeKey) }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "shortcutOverview"
        statusItem.button?.image = keysMenuBarImage()
        statusItem.button?.setAccessibilityLabel("AMS Shortcut Overview")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        desktop = DesktopController(model: model)

        if !UserDefaults.standard.bool(forKey: "didFirstStart") {
            UserDefaults.standard.set(true, forKey: "didFirstStart")
            try? SMAppService.mainApp.register()
        }
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURL(_:reply:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    // MARK: Menu bar menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(item("Add shortcut…", #selector(addShortcut), key: "n"))
        menu.addItem(item("Shortcuts and settings…", #selector(openManage), key: ","))
        menu.addItem(.separator())
        let show = item("Show cards on the desktop", #selector(toggleCards))
        show.state = model.showCards ? .on : .off
        menu.addItem(show)
        let daily = item("Today's shortcuts", #selector(toggleDaily))
        daily.state = model.dailyPick ? .on : .off
        menu.addItem(daily)
        let quiz = item("Quiz me", #selector(toggleQuiz))
        quiz.state = model.quiz ? .on : .off
        menu.addItem(quiz)
        menu.addItem(.separator())
        let week = NSMenuItem(title: "Learned this week: \(model.learnedThisWeek)", action: nil, keyEquivalent: "")
        week.isEnabled = false
        menu.addItem(week)
        let v = NSMenuItem(title: "Version \(Guide.version)", action: nil, keyEquivalent: "")
        v.isEnabled = false
        menu.addItem(v)
        menu.addItem(item("Quit AMS Shortcut Overview", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc private func addShortcut() { openEditor(shortcut: nil, appName: "") }
    @objc private func toggleCards() { model.showCards.toggle(); desktop?.refresh() }
    @objc private func toggleDaily() { model.dailyPick.toggle(); desktop?.refresh() }
    @objc private func toggleQuiz() { model.quiz.toggle(); desktop?.refresh() }
    @objc private func quit() { NSApp.terminate(nil) }

    // MARK: Windows

    @objc func openManage() {
        if manageWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: ManageView(model: model)))
            w.title = "AMS Shortcut Overview"
            w.styleMask = [.titled, .closable, .miniaturizable]
            w.isReleasedWhenClosed = false
            w.center()
            manageWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        manageWindow?.makeKeyAndOrderFront(nil)
    }

    func openEditor(shortcut: Shortcut?, appName: String) {
        editorWindow?.close()
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        let view = EditorView(model: model, original: shortcut, appName: appName) { [weak w] in w?.close() }
        w.contentViewController = NSHostingController(rootView: view)
        w.title = shortcut == nil ? "New shortcut" : "Change shortcut"
        w.isReleasedWhenClosed = false
        w.level = .floating
        w.center()
        editorWindow = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    // MARK: Links for checks: amsshortcuts://settings | add | day | night | system | snapshot

    @objc private func handleURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let s = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let host = URL(string: s)?.host else { return }
        switch host {
        case "settings": openManage()
        case "dailyOn", "dailyOff": model.dailyPick = host == "dailyOn"; desktop?.refresh()
        case "quizOn", "quizOff": model.quiz = host == "quizOn"; desktop?.refresh()
        case "add": openEditor(shortcut: nil, appName: "")
        case "day", "night", "system":
            model.look = host
            desktop?.refresh()
            let app: NSAppearance? = host == "day" ? NSAppearance(named: .aqua)
                : host == "night" ? NSAppearance(named: .darkAqua) : nil
            NSApp.appearance = app
        case "snapshot":
            let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("com.schabbauer.AMSShortcutOverview", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            desktop?.snapshot(to: dir.appendingPathComponent("cards-\(model.look).png"))
            for (name, w) in [("manage", manageWindow), ("editor", editorWindow)] {
                guard let w, w.isVisible, let v = w.contentView,
                      let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { continue }
                v.cacheDisplay(in: v.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?
                    .write(to: dir.appendingPathComponent("\(name)-\(model.look).png"))
            }
        default: break
        }
    }
}
