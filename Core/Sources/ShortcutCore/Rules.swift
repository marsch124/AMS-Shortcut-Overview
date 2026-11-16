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

    public static func learnedCount(_ g: AppGroup, now: Date) -> Int {
        g.shortcuts.filter { status($0, now: now) == .learned }.count
    }

    /// Tick on the card: learning → learned (recheck in two weeks); recheck → learned for good.
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
