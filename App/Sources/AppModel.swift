import SwiftUI
import UniformTypeIdentifiers
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

    /// How many cards fit side by side on the screen; the desktop sets it.
    @Published var cardsPerRow = 6
    /// Set while the list could not be saved; shown in red in the window and the menu.
    @Published private(set) var saveProblem: String?
    /// Set when the list had to be restored from a safety copy; shown once in the window.
    @Published var restoreNotice: String?

    /// "Last export: 16 Nov 2026, 14:05 · 5 apps, 40 shortcuts" — kept across restarts.
    @AppStorage("lastExport") var lastExport = ""
    @Published private(set) var exportProblem: String?

    /// A list waiting for an answer: "Replace your list with this one?" for a file,
    /// "Put your earlier list back?" for Undo.
    struct PendingImport { let url: URL; let library: ShortcutLibrary; var isUndo = false }
    @Published var pendingImport: PendingImport?
    /// Which question is asked. Kept while the question closes, so its words do not change on the way out.
    @Published private(set) var askingUndo = false
    @Published private(set) var importNote = ""
    @Published private(set) var importProblem: String?
    /// The "before" copy of the last bring-in, for Undo. Kept across restarts.
    @AppStorage("lastBeforeFile") var lastBeforeFile = ""
    /// True when that "before" copy was made by an Undo, so the Undo question names it rightly.
    @AppStorage("lastBeforeWasUndo") var lastBeforeWasUndo = false

    /// For checks: AMS_SHORTCUTS_FOLDER points the app at a test list instead of the real one.
    static let testFolder: URL? = ProcessInfo.processInfo.environment["AMS_SHORTCUTS_FOLDER"]
        .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0, isDirectory: true) }

    let store: LibraryStore = {
        if let test = AppModel.testFolder { return LibraryStore(folder: test) }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return LibraryStore(folder: base.appendingPathComponent("AMS Shortcut Overview", isDirectory: true))
    }()
    var file: URL { store.file }

    private var timer: Timer?

    /// Apps a fresh install starts with; the last ready-made one (Safari) waits in "Add ready-made app".
    static let firstStartApps = ["Obsidian", "Raycast", "Fusion", "Finder", "Xcode"]

    init() {
        load()
        addFinderAndXcodeOnce()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
                if self?.saveProblem != nil { self?.save() }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
    }

    // MARK: Load and save

    func load() {
        let loaded = store.load()
        library = loaded.library ?? Self.starter()
        switch loaded.source {
        case .file: break
        case .safetyCopy:
            restoreNotice = "Your list could not be read. It was restored from the safety copy (the list before your last change). The unreadable file is kept next to it."
            save()
        case .dailyCopy(let day):
            restoreNotice = "Your list could not be read. It was restored from the dated safety copy of \(day). The unreadable file is kept next to it."
            save()
        case .nothing:
            if loaded.setAside != nil {
                restoreNotice = "Your list could not be read and no safety copy was usable, so the app started with the ready-made apps. The unreadable file is kept next to the list."
            }
            save()
        }
    }

    /// The ready-made apps that come with the app (Starter.json), 8 checked shortcuts each.
    static let readyMade: [AppGroup] = {
        guard let url = Bundle.main.url(forResource: "Starter", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lib = try? ShortcutLibrary.decode(data) else { return [] }
        return lib.groups
    }()

    static func starter() -> ShortcutLibrary {
        var lib = ShortcutLibrary()
        for g in readyMade where firstStartApps.contains(g.name) { Rules.addReadyMade(g, to: &lib) }
        return lib
    }

    /// 0.3: Finder and Xcode join an existing list once (skipped if an app of that name is there).
    private func addFinderAndXcodeOnce() {
        let flag = "addedFinderXcode03"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        UserDefaults.standard.set(true, forKey: flag)
        let new = Self.readyMade.filter { ["Finder", "Xcode"].contains($0.name) }
        let t = Date()   // the moment of the click, not the hourly clock
        change { lib in for g in new { Rules.addReadyMade(g, to: &lib, now: t) } }
    }

    private func save() {
        do {
            try store.save(library)
            saveProblem = nil
        } catch {
            saveProblem = "Could not save your list (\(error.localizedDescription)). The app tries again every hour and with your next change."
        }
    }

    // MARK: Export

    /// Asks where, then writes the whole list as one file to keep anywhere.
    func exportList() {
        let panel = NSSavePanel()
        panel.title = "Export my list"
        panel.message = "One file with every app and shortcut, learned and removed ones too."
        panel.nameFieldStringValue = LibraryStore.exportName(Date())
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        export(to: url)
    }

    func export(to url: URL) {
        do {
            try LibraryStore.export(library, to: url)
            let when = Date().formatted(.dateTime.day().month(.abbreviated).year().hour().minute())
            lastExport = "Last export: \(when) · \(Self.counts(library))"
            exportProblem = nil
        } catch {
            exportProblem = "Could not export: \(error.localizedDescription)"
        }
    }

    // MARK: Bring a list back in

    /// "7 apps and 57 shortcuts, plus 1 app and 8 shortcuts on the Removed page" — the same words
    /// in both questions, the "Brought in" line and the "Last export" line.
    static func counts(_ lib: ShortcutLibrary) -> String { Rules.countWords(lib.groups) }

    /// The note under "Replace your list with this one?" / "Put your earlier list back?".
    func question(for pending: PendingImport) -> String {
        let nowHolds = "Your list now holds \(Self.counts(library))."
        if pending.isUndo {
            let what = lastBeforeWasUndo ? "Undo" : "bring-in"
            return "This is the list you had before the last \(what): \(Self.counts(pending.library)). \(nowHolds) It is kept as a safety copy first, so this can be undone too."
        }
        return "The file \u{201C}\(pending.url.lastPathComponent)\u{201D} holds \(Self.counts(pending.library)). \(nowHolds) It is kept as a safety copy first, so you can undo this."
    }

    /// Asks which file, checks it, and then waits for the "Replace your list?" answer.
    func chooseListToBringIn() {
        let panel = NSOpenPanel()
        panel.title = "Bring a list back in"
        panel.message = "Choose a list you exported earlier."
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        offerList(at: url)
    }

    /// Checks a file and, if it is a list, puts the question. Changes nothing yet.
    func offerList(at url: URL, isUndo: Bool = false) {
        do {
            let list = try LibraryStore.readList(at: url)
            askingUndo = isUndo
            pendingImport = PendingImport(url: url, library: list, isUndo: isUndo)
            importProblem = nil
        } catch {
            pendingImport = nil
            importNote = ""
            importProblem = isUndo ? "Your earlier list could not be read. Nothing was changed."
                : "This file is not a list from AMS Shortcut Overview. Nothing was changed."
        }
    }

    /// The "before" copy of the last bring-in, if it still exists.
    var undoFile: URL? {
        guard !lastBeforeFile.isEmpty else { return nil }
        let url = store.copies.appendingPathComponent(lastBeforeFile)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// "Undo": asks "Put your earlier list back?" for the "before" copy. Changes nothing yet.
    func offerUndo() { if let url = undoFile { offerList(at: url, isUndo: true) } }

    /// "Replace my list" / "Put it back": keeps the list as it is now as a "before" copy, then replaces it.
    func bringInPending() {
        guard let pending = pendingImport else { return }
        pendingImport = nil
        do {
            let before = try store.replace(with: pending.library, current: library)
            library = pending.library
            now = Date()
            saveProblem = nil
            lastBeforeFile = before.lastPathComponent
            lastBeforeWasUndo = pending.isUndo
            let c = Self.counts(pending.library)
            importNote = pending.isUndo
                ? "Your earlier list is back: \(c). The list you had just now is kept, press Undo to return to it."
                : "Brought in \(c). Your list from before is kept, press Undo to get it back."
            importProblem = nil
        } catch {
            importProblem = pending.isUndo
                ? "Could not put your earlier list back: \(error.localizedDescription) Nothing was changed."
                : "Could not bring the list in: \(error.localizedDescription) Nothing was changed."
        }
    }

    private func change(_ edit: (inout ShortcutLibrary) -> Void) {
        now = Date()
        var lib = library
        edit(&lib)
        library = lib
        save()
    }

    // MARK: Questions

    func cardRows(_ g: AppGroup) -> [Shortcut] { Rules.ordered(g, now: now, daily: dailyPick) }

    /// Your list as the pages see it: without removed apps and removed shortcuts.
    var groups: [AppGroup] { Rules.active(library.groups) }

    var visibleGroups: [AppGroup] {
        groups.filter { !Rules.visible($0, now: now).isEmpty }
    }

    var removedApps: [AppGroup] { Rules.removedApps(library.groups) }
    var removedShortcuts: [AppGroup] { Rules.removedShortcuts(library.groups) }

    /// Weeks in a row with at least one shortcut learned.
    var weekStreak: Int { Rules.weekStreak(library.groups, now: Date()) }

    /// "Learned this week: 3" and, from two weeks up, " · 2 weeks in a row".
    var streakWords: String { weekStreak >= 2 ? " · \(weekStreak) weeks in a row" : "" }

    func status(_ s: Shortcut) -> ShortcutStatus { Rules.status(s, now: now) }

    var learnedThisWeek: Int { Rules.learnedThisWeek(library.groups, now: Date()) }

    var learnedInAll: Int { groups.reduce(0) { $0 + Rules.learnedCount($1, now: now) } }

    /// Ready-made apps not on the list yet.
    var readyMadeMissing: [AppGroup] {
        Self.readyMade.filter { r in !groups.contains { $0.name.caseInsensitiveCompare(r.name) == .orderedSame } }
    }

    // MARK: Changes

    func tick(_ id: UUID) {
        let t = Date()   // the moment of the click, not the hourly clock
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
                // Adding to an app on the Removed page brings its card back.
                if lib.groups[g].removedAt != nil { Rules.bringBackGroup(lib.groups[g].id, in: &lib) }
                if let old, old.group == lib.groups[g].id,
                   old.index <= lib.groups[g].shortcuts.count {
                    lib.groups[g].shortcuts.insert(s, at: old.index)
                } else {
                    lib.groups[g].shortcuts.append(s)
                }
            } else {
                let colour = Rules.nextColour(used: Rules.active(lib.groups).map(\.colour))
                lib.groups.append(AppGroup(name: name, colour: colour, shortcuts: [s]))
            }
            lib.groups.removeAll { $0.shortcuts.isEmpty }
        }
    }

    /// Moves a shortcut to the Removed page. Nothing is ever deleted.
    func remove(_ id: UUID) {
        let t = Date()   // the moment of the click, not the hourly clock
        change { lib in Rules.removeShortcut(id, in: &lib, now: t) }
    }

    func bringBackRemoved(_ id: UUID) {
        change { lib in Rules.bringBackShortcut(id, in: &lib) }
    }

    func addReadyMade(_ g: AppGroup) {
        let t = Date()   // the moment of the click, not the hourly clock
        change { lib in Rules.addReadyMade(g, to: &lib, now: t) }
    }

    /// Moves an app's card with all its shortcuts to the Removed page.
    func removeGroup(_ id: UUID) {
        let t = Date()   // the moment of the click, not the hourly clock
        change { lib in Rules.removeGroup(id, in: &lib, now: t) }
    }

    func bringBackGroup(_ id: UUID) {
        change { lib in Rules.bringBackGroup(id, in: &lib) }
    }

    func setColour(_ colour: String, group: UUID) {
        change { lib in
            if let g = lib.groups.firstIndex(where: { $0.id == group }) { lib.groups[g].colour = colour }
        }
    }

    func moveGroup(_ id: UUID, by step: Int) {
        change { lib in Rules.moveGroup(id, by: step, in: &lib) }
    }

    func groupName(of id: UUID) -> String? {
        library.groups.first { $0.shortcuts.contains { $0.id == id } }?.name
    }
}
