import Foundation

/// Keeps the list on this Mac: the list file, a safety copy of the list before the last change,
/// and one dated copy per day (the list before that day's first change) for 30 days.
public struct LibraryStore {
    public static let keepDays = 30

    public let folder: URL
    public init(folder: URL) { self.folder = folder }

    public var file: URL { folder.appendingPathComponent("shortcuts.json") }
    public var backup: URL { folder.appendingPathComponent("shortcuts-safety-copy.json") }
    public var copies: URL { folder.appendingPathComponent("Safety copies", isDirectory: true) }

    /// Where a loaded list came from.
    public enum Source: Equatable { case file, safetyCopy, dailyCopy(String), nothing }

    public struct Loaded {
        /// nil = no good list anywhere (a first start).
        public let library: ShortcutLibrary?
        public let source: Source
        /// A list file that could not be used and was put aside, never overwritten.
        public let setAside: URL?
    }

    public enum SaveError: Error, Equatable { case emptyOverGoodList }

    private var fm: FileManager { .default }

    /// A list that can be read and has at least one app. The app only ever hides things,
    /// so a real list is never empty: "no apps at all" means a damaged file.
    static func good(_ url: URL) -> ShortcutLibrary? {
        guard let data = try? Data(contentsOf: url),
              let lib = try? ShortcutLibrary.decode(data), !lib.groups.isEmpty else { return nil }
        return lib
    }

    /// The dated copies' file names, newest first.
    public func dailyCopyNames() -> [String] {
        ((try? fm.contentsOfDirectory(atPath: copies.path)) ?? [])
            .filter { $0.hasPrefix("shortcuts-") && $0.hasSuffix(".json") }
            .sorted(by: >)
    }

    public func load(now: Date = Date()) -> Loaded {
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        if let lib = Self.good(file) { return Loaded(library: lib, source: .file, setAside: nil) }
        var aside: URL?
        if fm.fileExists(atPath: file.path) {
            let to = folder.appendingPathComponent("shortcuts-unreadable-\(Int(now.timeIntervalSince1970)).json")
            if (try? fm.moveItem(at: file, to: to)) != nil { aside = to }
        }
        if let lib = Self.good(backup) { return Loaded(library: lib, source: .safetyCopy, setAside: aside) }
        for name in dailyCopyNames() {
            if let lib = Self.good(copies.appendingPathComponent(name)) {
                let day = String(name.dropFirst("shortcuts-".count).dropLast(".json".count))
                return Loaded(library: lib, source: .dailyCopy(day), setAside: aside)
            }
        }
        return Loaded(library: nil, source: .nothing, setAside: aside)
    }

    /// Writes the list. Before that, a good list file is copied to the safety copy and,
    /// once per day, to a dated copy. An empty list never replaces a good one.
    public func save(_ lib: ShortcutLibrary, now: Date = Date(), calendar: Calendar = .current) throws {
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try lib.encoded()
        if Self.good(file) != nil {
            if lib.groups.isEmpty { throw SaveError.emptyOverGoodList }
            try? fm.createDirectory(at: copies, withIntermediateDirectories: true)
            let today = copies.appendingPathComponent(Self.copyName(now, calendar: calendar))
            if !fm.fileExists(atPath: today.path) {
                try? fm.copyItem(at: file, to: today)
                for old in Self.namesToDelete(dailyCopyNames()) {
                    try? fm.removeItem(at: copies.appendingPathComponent(old))
                }
            }
            try? fm.removeItem(at: backup)
            try? fm.copyItem(at: file, to: backup)
        }
        try data.write(to: file, options: .atomic)
    }

    /// "shortcuts-2026-11-16.json"
    public static func copyName(_ day: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "shortcuts-%04d-%02d-%02d.json", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The name offered for an export: "AMS Shortcut Overview list 2026-11-16.json".
    public static func exportName(_ day: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "AMS Shortcut Overview list %04d-%02d-%02d.json", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Writes the whole list (learned and removed ones too) to a file of the user's choice.
    /// Same form as the app's own list file. Changes nothing in the list.
    public static func export(_ lib: ShortcutLibrary, to url: URL) throws {
        try lib.encoded().write(to: url, options: .atomic)
    }

    // MARK: Bring a list back in

    public enum ImportError: Error, Equatable { case notAList }

    /// Reads a list file someone chose. Refused when it cannot be read, holds no apps,
    /// or an app in it has no name (a file that is not one of this app's lists).
    public static func readList(at url: URL) throws -> ShortcutLibrary {
        guard let lib = good(url),
              !lib.groups.contains(where: { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw ImportError.notAList }
        return lib
    }

    /// "before-bringing-in-2026-11-16-152233.json" — the list as it was before a bring-in.
    /// Not a "shortcuts-…" name on purpose: the 30-day clearing and the automatic recovery never touch it.
    public static func beforeName(_ now: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        return String(format: "before-bringing-in-%04d-%02d-%02d-%02d%02d%02d.json",
                      c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }

    /// Replaces the list. First the current list is written as its own "before" file in
    /// "Safety copies"; if that fails, nothing is replaced. Returns the "before" file.
    @discardableResult
    public func replace(with new: ShortcutLibrary, current: ShortcutLibrary,
                        now: Date = Date(), calendar: Calendar = .current) throws -> URL {
        if new.groups.isEmpty { throw ImportError.notAList }
        try fm.createDirectory(at: copies, withIntermediateDirectories: true)
        let before = copies.appendingPathComponent(Self.beforeName(now, calendar: calendar))
        try current.encoded().write(to: before, options: .atomic)
        try save(new, now: now, calendar: calendar)
        return before
    }

    /// The dated copies beyond the newest 30.
    public static func namesToDelete(_ names: [String], keep: Int = keepDays) -> [String] {
        Array(names.sorted(by: >).dropFirst(keep))
    }
}
