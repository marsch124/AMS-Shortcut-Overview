import SwiftUI
import ShortcutCore

/// Holds the shortcut list, saves it on this Mac, and keeps a safety copy.
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var library = ShortcutLibrary()
    @Published var now = Date()
    @AppStorage("showCards") var showCards = true
    @AppStorage("rowsPerCard") var rowsPerCard = 6
    /// A fresh pick of shortcuts each day instead of list order.
    @AppStorage("dailyPick") var dailyPick = false
    /// Hide the keys until you point at the row.
    @AppStorage("quiz") var quiz = false
    /// "system", "day" or "night" — for checks; normal use is "system".
    @AppStorage("look") var look = "system"

    let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("AMS Shortcut Overview", isDirectory: true)
    }()
    var file: URL { folder.appendingPathComponent("shortcuts.json") }
    var backup: URL { folder.appendingPathComponent("shortcuts-safety-copy.json") }

    private var timer: Timer?

    init() {
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
    }

    // MARK: Load and save

    func load() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: file), let lib = try? ShortcutLibrary.decode(data) {
            library = lib
        } else if let data = try? Data(contentsOf: backup), let lib = try? ShortcutLibrary.decode(data) {
            library = lib
        } else if FileManager.default.fileExists(atPath: file.path) {
            // A file we cannot read: keep it aside, never overwrite it.
            let aside = folder.appendingPathComponent("shortcuts-unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: file, to: aside)
            library = Self.starter()
            save()
        } else {
            library = Self.starter()
            save()
        }
    }

    static func starter() -> ShortcutLibrary {
        guard let url = Bundle.main.url(forResource: "Starter", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lib = try? ShortcutLibrary.decode(data) else { return ShortcutLibrary() }
        return lib
    }

    private func save() {
        guard let data = try? library.encoded() else { return }
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.copyItem(at: file, to: backup)
        }
        try? data.write(to: file, options: .atomic)
    }

    private func change(_ edit: (inout ShortcutLibrary) -> Void) {
        var lib = library
        edit(&lib)
        library = lib
        save()
    }

    // MARK: Questions

    func cardRows(_ g: AppGroup) -> [Shortcut] { Rules.ordered(g, now: now, daily: dailyPick) }

    var visibleGroups: [AppGroup] {
        library.groups.filter { !Rules.visible($0, now: now).isEmpty }
    }

    func status(_ s: Shortcut) -> ShortcutStatus { Rules.status(s, now: now) }

    // MARK: Changes

    func tick(_ id: UUID) {
        let t = now
        change { lib in
            for g in lib.groups.indices {
                if let i = lib.groups[g].shortcuts.firstIndex(where: { $0.id == id }) {
                    Rules.tick(&lib.groups[g].shortcuts[i], now: t)
                }
            }
        }
    }

    func bringBack(_ id: UUID) {
        change { lib in
            for g in lib.groups.indices {
                if let i = lib.groups[g].shortcuts.firstIndex(where: { $0.id == id }) {
                    Rules.bringBack(&lib.groups[g].shortcuts[i])
                }
            }
        }
    }

    /// Saves a new or changed shortcut. A new app name makes a new card with the next colour.
    func save(shortcut: Shortcut, appName: String) {
        let name = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        var s = shortcut
        s.keys = Rules.cleanKeys(s.keys)
        s.name = s.name.trimmingCharacters(in: .whitespacesAndNewlines)
        var old: (group: UUID, index: Int)?
        for g in library.groups {
            if let i = g.shortcuts.firstIndex(where: { $0.id == s.id }) { old = (g.id, i) }
        }
        change { lib in
            for g in lib.groups.indices { lib.groups[g].shortcuts.removeAll { $0.id == s.id } }
            if let g = lib.groups.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                if let old, old.group == lib.groups[g].id,
                   old.index <= lib.groups[g].shortcuts.count {
                    lib.groups[g].shortcuts.insert(s, at: old.index)
                } else {
                    lib.groups[g].shortcuts.append(s)
                }
            } else {
                let colour = Rules.nextColour(used: lib.groups.map(\.colour))
                lib.groups.append(AppGroup(name: name, colour: colour, shortcuts: [s]))
            }
            lib.groups.removeAll { $0.shortcuts.isEmpty }
        }
    }

    func delete(_ id: UUID) {
        change { lib in
            for g in lib.groups.indices { lib.groups[g].shortcuts.removeAll { $0.id == id } }
            lib.groups.removeAll { $0.shortcuts.isEmpty }
        }
    }

    func setColour(_ colour: String, group: UUID) {
        change { lib in
            if let g = lib.groups.firstIndex(where: { $0.id == group }) { lib.groups[g].colour = colour }
        }
    }

    func moveGroup(_ id: UUID, by step: Int) {
        change { lib in
            guard let i = lib.groups.firstIndex(where: { $0.id == id }) else { return }
            let j = i + step
            guard lib.groups.indices.contains(j) else { return }
            lib.groups.swapAt(i, j)
        }
    }

    func groupName(of id: UUID) -> String? {
        library.groups.first { $0.shortcuts.contains { $0.id == id } }?.name
    }
}
