import Foundation

struct GuideSection: Identifiable { let id = UUID(); let title: String; let colour: String; let body: String }
struct Release: Identifiable { let id = UUID(); let version: String; let date: String; let items: [String] }

enum Guide {
    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    static let howItWorks: [GuideSection] = [
        GuideSection(title: "What this app is for", colour: "purple", body: "AMS Shortcut Overview helps you learn keyboard shortcuts. It puts one colour card per app on your desktop, along the bottom of the screen, behind all your windows. Each card lists the shortcuts you are still learning. You see them every time you look at the desktop, so they stick. It works on the Mac only, has no Dock icon, and nothing leaves your Mac."),
        GuideSection(title: "The cards on the desktop", colour: "coral", body: "Every app has its own card in its own colour: the app's name at the top, then one row per shortcut. On the left of each row is a small circle, in the middle what the shortcut does, and on the right the keys to press, drawn as little keys. ⌘ is Command, ⌥ is Option, ⌃ is Control and ⇧ is Shift.\n\nA card shows up to 6 shortcuts. If there are more, it says \"+2 more\" at the bottom; the next ones move up as you learn the first. The number of rows can be changed in Settings. The top right of a card says how many of that app's shortcuts you have learned.\n\nThe cards sit at desktop level: windows always cover them. To see them, move your windows aside or show the desktop (for example by clicking the wallpaper, or with a spread of thumb and three fingers on the trackpad)."),
        GuideSection(title: "Ticking a shortcut off", colour: "teal", body: "When you know a shortcut, click its circle. A tick appears, the row is crossed out, and after a moment it disappears from the card. You can also right-click a row and choose \"I know it\".\n\nTwo weeks later the shortcut comes back once, at the top of its card, with a small \"Recheck\" label. If you still know it, tick it again and it is gone for good. If you have forgotten it, right-click it and choose \"Still learning\": it stays on the card as before.\n\nWhen every shortcut of an app is learned, its card disappears from the desktop."),
        GuideSection(title: "Adding and changing shortcuts", colour: "blue", body: "Three ways to add one:\n1. Click the small + at the top right of a card: the new shortcut goes to that app.\n2. Click the key icon in the menu bar and choose \"Add shortcut…\".\n3. In the window, press \"Add shortcut\" at the bottom of the Shortcuts page.\n\nFill in the app, what the shortcut does, and the keys. Type the keys, or press the ⌘ ⌥ ⌃ ⇧ buttons to add a symbol, then type the letter. \"Looks like\" shows how it will look on the card. Save, or Cancel (Escape also cancels).\n\nType a new app name and the app gets a new card with the next free colour. To change or delete a shortcut, right-click it on its card and choose \"Change…\", or press \"Change\" next to it on the Shortcuts page. The Delete button is in the same window."),
        GuideSection(title: "The window", colour: "pink", body: "Click the key icon in the menu bar and choose \"Shortcuts and settings…\". The window has five pages:\n• Shortcuts: every shortcut of every app, with its state (empty = still learning, Recheck, Learned). Click the coloured dot next to an app's name to change its colour: every click tries the next of 7 colours; \"Move left\" and \"Move right\" change the order of the cards on the desktop.\n• Learned: everything you have learned, with the date of its recheck, or \"Learned for good\". \"Bring back\" puts a shortcut back on its card.\n• Settings: show or hide the cards, shortcuts per card (3 to 12), open at login, where your list is kept, and the version.\n• How it works: this guide.\n• What's new: every version, newest first."),
        GuideSection(title: "Your list is safe", colour: "amber", body: "Your shortcuts are kept in a file on this Mac (Settings, \"Show in Finder\"). Before every change the app keeps a safety copy of the previous list next to it. If the list ever cannot be read, the app puts that file aside instead of overwriting it and starts from the safety copy. The first time it starts, the app fills in 8 shortcuts each for Obsidian, Raycast and Fusion."),
    ]

    static let releases: [Release] = [
        Release(version: "0.1 (1)", date: "16 Nov 2026", items: [
            "New app. One colour card per app sits on your desktop, along the bottom of the screen, behind your windows: Obsidian in purple, Raycast in coral, Fusion in teal, each starting with 8 shortcuts.",
            "Each row shows what the shortcut does and its keys, drawn as little keys.",
            "Tick a shortcut's circle when you know it: it is crossed out and disappears. Two weeks later it comes back once with a \"Recheck\" label; tick it again and it is gone for good, or choose \"Still learning\" to keep it.",
            "A card shows up to 6 shortcuts and \"+N more\"; it shows how many you have learned, and it disappears when all are learned.",
            "Add shortcuts with the + on a card, from the key icon in the menu bar, or in the window. A new app name gets a new card with the next free colour.",
            "Change or delete a shortcut by right-clicking it on its card, or in the window.",
            "The window has five pages: Shortcuts, Learned (with \"Bring back\"), Settings, How it works and What's new.",
            "Settings: show or hide the cards, shortcuts per card (3 to 12), open at login, where your list is kept, version number.",
            "Change an app's colour and the order of the cards.",
            "Your list stays on this Mac, with a safety copy before every change.",
            "Day and night colours for every card.",
        ]),
    ]
}
