import Foundation

public enum ShortcutStatus: Equatable { case learning, recheck, learned }

public enum Rules {
    /// A learned shortcut comes back once after this many days.
    public static let recheckAfterDays = 14
    /// Colours handed out to new apps, in this order.
    public static let colours = ["purple", "coral", "teal", "blue", "pink", "amber", "green"]

    public static func status(_ s: Shortcut, now: Date, calendar: Calendar = .current) -> ShortcutStatus {
        guard let learned = s.learnedAt else { return .learning }
        if s.recheckDone { return .learned }
        let due = calendar.date(byAdding: .day, value: recheckAfterDays, to: learned) ?? learned
        return now >= due ? .recheck : .learned
    }

    /// What a card shows: rechecks first, then the ones still being learned, in list order.
    public static func visible(_ g: AppGroup, now: Date) -> [Shortcut] {
        let r = g.shortcuts.filter { status($0, now: now) == .recheck }
        let l = g.shortcuts.filter { status($0, now: now) == .learning }
        return r + l
    }

    /// What a card shows, optionally as today's pick: rechecks first, then the learning ones
    /// shuffled once per day (same order all day, new order after midnight).
    public static func ordered(_ g: AppGroup, now: Date, daily: Bool, calendar: Calendar = .current) -> [Shortcut] {
        guard daily else { return visible(g, now: now) }
        let c = calendar.dateComponents([.year, .month, .day], from: now)
        let day = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        let r = g.shortcuts.filter { status($0, now: now, calendar: calendar) == .recheck }
        let l = g.shortcuts.filter { status($0, now: now, calendar: calendar) == .learning }
            .sorted { stableHash(day + "|" + $0.id.uuidString) < stableHash(day + "|" + $1.id.uuidString) }
        return r + l
    }

    /// FNV-1a: the same number on every start (Swift's own hash changes each launch).
    static func stableHash(_ text: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in text.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        return h
    }

    public static func learnedCount(_ g: AppGroup, now: Date) -> Int {
        g.shortcuts.filter { status($0, now: now) == .learned }.count
    }

    /// Tick on the card: learning → learned (recheck in two weeks); recheck → learned, no more rechecks.
    public static func tick(_ s: inout Shortcut, now: Date) {
        switch status(s, now: now) {
        case .learning: s.learnedAt = now; s.recheckDone = false
        case .recheck: s.recheckDone = true
        case .learned: break
        }
    }

    /// Back on the card as "still learning".
    public static func bringBack(_ s: inout Shortcut) { s.learnedAt = nil; s.recheckDone = false }

    /// The first colour no app uses yet; when all are used, start again.
    public static func nextColour(used: [String]) -> String {
        colours.first { !used.contains($0) } ?? colours[used.count % colours.count]
    }

    /// How many shortcuts were first ticked as learned in the current calendar week.
    public static func learnedThisWeek(_ groups: [AppGroup], now: Date, calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return groups.flatMap(\.shortcuts).filter { s in
            guard let d = s.learnedAt else { return false }
            return d >= week.start && d < week.end
        }.count
    }

    /// Adds a ready-made app's card unless an app of that name is already on the list.
    /// An app of that name on the Removed page comes back as it was instead of a second copy.
    /// Fresh ids; its own colour if free, otherwise the next free one. Returns false when skipped.
    @discardableResult
    public static func addReadyMade(_ group: AppGroup, to lib: inout ShortcutLibrary, now: Date = Date()) -> Bool {
        if let old = lib.groups.first(where: { $0.name.caseInsensitiveCompare(group.name) == .orderedSame }) {
            guard !isOnList(old) else { return false }
            bringBackGroup(old.id, in: &lib)
            return true
        }
        let used = active(lib.groups).map(\.colour)
        let colour = used.contains(group.colour) ? nextColour(used: used) : group.colour
        let shortcuts = group.shortcuts.map { Shortcut(name: $0.name, keys: $0.keys, addedAt: now) }
        lib.groups.append(AppGroup(name: group.name, colour: colour, shortcuts: shortcuts))
        return true
    }

    // MARK: Removed — nothing is ever deleted, only hidden

    /// An app that shows on the list: not removed, with at least one shortcut that is not removed.
    public static func isOnList(_ g: AppGroup) -> Bool {
        g.removedAt == nil && g.shortcuts.contains { $0.removedAt == nil }
    }

    /// Your list as every page and card sees it: the apps on the list, each without its removed shortcuts.
    public static func active(_ groups: [AppGroup]) -> [AppGroup] {
        groups.filter(isOnList).map { g in
            var c = g; c.shortcuts = g.shortcuts.filter { $0.removedAt == nil }; return c
        }
    }

    /// Whole apps on the Removed page, each with every shortcut it holds.
    public static func removedApps(_ groups: [AppGroup]) -> [AppGroup] { groups.filter { $0.removedAt != nil } }

    /// Single removed shortcuts, under their app (apps that were not removed as a whole).
    public static func removedShortcuts(_ groups: [AppGroup]) -> [AppGroup] {
        groups.filter { $0.removedAt == nil }.compactMap { g in
            var c = g; c.shortcuts = g.shortcuts.filter { $0.removedAt != nil }
            return c.shortcuts.isEmpty ? nil : c
        }
    }

    /// How much a list holds: what is on the list, and apart from it what is on the Removed page.
    public struct Counts: Equatable {
        public var apps = 0, shortcuts = 0, removedApps = 0, removedShortcuts = 0
    }

    /// On the list: the apps every page shows, with their shortcuts that are not removed.
    /// On the Removed page: the whole apps there, and every shortcut that stands there
    /// (those of removed apps and the single removed ones).
    public static func counts(_ groups: [AppGroup]) -> Counts {
        let on = active(groups)
        let shown = on.reduce(0) { $0 + $1.shortcuts.count }
        let all = groups.reduce(0) { $0 + $1.shortcuts.count }
        return Counts(apps: on.count, shortcuts: shown,
                      removedApps: removedApps(groups).count, removedShortcuts: all - shown)
    }

    /// "7 apps and 57 shortcuts, plus 1 app and 8 shortcuts on the Removed page".
    /// The Removed page is only named when something is on it.
    public static func countWords(_ groups: [AppGroup]) -> String {
        let c = counts(groups)
        func apps(_ n: Int) -> String { n == 1 ? "1 app" : "\(n) apps" }
        func shortcuts(_ n: Int) -> String { n == 1 ? "1 shortcut" : "\(n) shortcuts" }
        var words = "\(apps(c.apps)) and \(shortcuts(c.shortcuts))"
        if c.removedApps > 0 {
            words += ", plus \(apps(c.removedApps)) and \(shortcuts(c.removedShortcuts)) on the Removed page"
        } else if c.removedShortcuts > 0 {
            words += ", plus \(shortcuts(c.removedShortcuts)) on the Removed page"
        }
        return words
    }

    public static func removeShortcut(_ id: UUID, in lib: inout ShortcutLibrary, now: Date) {
        for g in lib.groups.indices {
            if let i = lib.groups[g].shortcuts.firstIndex(where: { $0.id == id }) {
                lib.groups[g].shortcuts[i].removedAt = now
            }
        }
    }

    public static func bringBackShortcut(_ id: UUID, in lib: inout ShortcutLibrary) {
        for g in lib.groups.indices {
            if let i = lib.groups[g].shortcuts.firstIndex(where: { $0.id == id }) {
                lib.groups[g].shortcuts[i].removedAt = nil
            }
        }
    }

    public static func removeGroup(_ id: UUID, in lib: inout ShortcutLibrary, now: Date) {
        if let g = lib.groups.firstIndex(where: { $0.id == id }) { lib.groups[g].removedAt = now }
    }

    /// The app's card comes back as it was. If every one of its shortcuts was removed one by one,
    /// they all come back, so the card is not empty. A colour another app took meanwhile is swapped
    /// for the next free one.
    public static func bringBackGroup(_ id: UUID, in lib: inout ShortcutLibrary) {
        guard let g = lib.groups.firstIndex(where: { $0.id == id }) else { return }
        let used = active(lib.groups.filter { $0.id != id }).map(\.colour)
        lib.groups[g].removedAt = nil
        if !lib.groups[g].shortcuts.contains(where: { $0.removedAt == nil }) {
            for i in lib.groups[g].shortcuts.indices { lib.groups[g].shortcuts[i].removedAt = nil }
        }
        if used.contains(lib.groups[g].colour) { lib.groups[g].colour = nextColour(used: used) }
    }

    /// Move left / right among the apps on the list; removed apps in between are stepped over.
    public static func moveGroup(_ id: UUID, by step: Int, in lib: inout ShortcutLibrary) {
        let shown = lib.groups.indices.filter { isOnList(lib.groups[$0]) }
        guard let p = shown.firstIndex(where: { lib.groups[$0].id == id }), shown.indices.contains(p + step) else { return }
        lib.groups.swapAt(shown[p], shown[p + step])
    }

    // MARK: Weeks in a row

    /// How many weeks in a row at least one shortcut was learned. The current week does not
    /// break the run while it has no tick yet: the run ends when a full week passes with none.
    public static func weekStreak(_ groups: [AppGroup], now: Date, calendar: Calendar = .current) -> Int {
        guard var week = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        let weeks = Set(groups.flatMap(\.shortcuts).compactMap { s in
            s.learnedAt.flatMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start }
        })
        if !weeks.contains(week) {
            guard let before = calendar.date(byAdding: .weekOfYear, value: -1, to: week) else { return 0 }
            week = before
        }
        var count = 0
        while weeks.contains(week), count < 5000 {
            count += 1
            guard let before = calendar.date(byAdding: .weekOfYear, value: -1, to: week) else { break }
            week = before
        }
        return count
    }

    // MARK: Rows of cards

    /// How many cards fit side by side in this width.
    public static func cardsPerRow(width: Double, card: Double = 260, gap: Double = 10) -> Int {
        max(1, Int((width + gap) / (card + gap)))
    }

    /// Cards in rows, bottom row first: the first cards keep their place on the bottom row,
    /// the ones that do not fit go to a row above.
    public static func cardRows<T>(_ items: [T], perRow: Int) -> [[T]] {
        let n = max(1, perRow)
        return stride(from: 0, to: items.count, by: n).map { Array(items[$0..<min($0 + n, items.count)]) }
    }

    /// "⌘ ⇧ F" → ["⌘","⇧","F"]. Also splits "⌘⇧F" written without spaces.
    public static func keyParts(_ keys: String) -> [String] {
        let modifiers: Set<Character> = ["⌘", "⌥", "⌃", "⇧"]
        var parts: [String] = []
        for token in keys.split(separator: " ") {
            var rest = Substring(token)
            while let f = rest.first, modifiers.contains(f), rest.count > 1 {
                parts.append(String(f)); rest = rest.dropFirst()
            }
            if !rest.isEmpty { parts.append(String(rest)) }
        }
        return parts
    }

    /// Tidy what someone typed: trims, one space between keys, letters upper case.
    public static func cleanKeys(_ keys: String) -> String {
        keyParts(keys.trimmingCharacters(in: .whitespacesAndNewlines))
            .map { $0.count == 1 ? $0.uppercased() : $0 }
            .joined(separator: " ")
    }
}
