import Foundation

/// One shortcut to learn, for example "Quick switcher" = "⌘ O".
public struct Shortcut: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    /// Keys separated by single spaces: "⌘ ⇧ F".
    public var keys: String
    /// When it was ticked as learned. nil = still learning.
    public var learnedAt: Date?
    /// The one recheck after two weeks was passed: no more rechecks. It stays in the list.
    public var recheckDone: Bool
    public var addedAt: Date
    /// Moved to the Removed page: hidden everywhere else, never deleted. nil = on the list.
    public var removedAt: Date?

    public init(id: UUID = UUID(), name: String, keys: String, learnedAt: Date? = nil,
                recheckDone: Bool = false, addedAt: Date = Date(), removedAt: Date? = nil) {
        self.id = id; self.name = name; self.keys = keys
        self.learnedAt = learnedAt; self.recheckDone = recheckDone; self.addedAt = addedAt
        self.removedAt = removedAt
    }

    enum CodingKeys: String, CodingKey { case id, name, keys, learnedAt, recheckDone, addedAt, removedAt }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        keys = (try? c.decodeIfPresent(String.self, forKey: .keys)) ?? ""
        learnedAt = try? c.decodeIfPresent(Date.self, forKey: .learnedAt)
        recheckDone = (try? c.decodeIfPresent(Bool.self, forKey: .recheckDone)) ?? false
        addedAt = (try? c.decodeIfPresent(Date.self, forKey: .addedAt)) ?? Date()
        removedAt = try? c.decodeIfPresent(Date.self, forKey: .removedAt)
    }
}

/// One app's card: "Obsidian" in purple with its shortcuts.
public struct AppGroup: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var colour: String
    public var shortcuts: [Shortcut]
    /// The whole app moved to the Removed page: its card is hidden, its shortcuts are kept.
    public var removedAt: Date?

    public init(id: UUID = UUID(), name: String, colour: String, shortcuts: [Shortcut] = [], removedAt: Date? = nil) {
        self.id = id; self.name = name; self.colour = colour; self.shortcuts = shortcuts
        self.removedAt = removedAt
    }

    enum CodingKeys: String, CodingKey { case id, name, colour, shortcuts, removedAt }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? ""
        colour = (try? c.decodeIfPresent(String.self, forKey: .colour)) ?? "purple"
        shortcuts = (try? c.decodeIfPresent([Shortcut].self, forKey: .shortcuts)) ?? []
        removedAt = try? c.decodeIfPresent(Date.self, forKey: .removedAt)
    }
}

public struct ShortcutLibrary: Codable, Equatable {
    public var version: Int
    public var groups: [AppGroup]

    public init(version: Int = 1, groups: [AppGroup] = []) { self.version = version; self.groups = groups }

    enum CodingKeys: String, CodingKey { case version, groups }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? 1
        groups = (try? c.decodeIfPresent([AppGroup].self, forKey: .groups)) ?? []
    }

    public static func decode(_ data: Data) throws -> ShortcutLibrary {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        return try d.decode(ShortcutLibrary.self, from: data)
    }
    public func encoded() throws -> Data {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(self)
    }
}
