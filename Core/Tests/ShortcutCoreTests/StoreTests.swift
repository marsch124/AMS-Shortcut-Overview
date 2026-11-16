import XCTest
@testable import ShortcutCore

/// Saving and loading: the list must never be lost.
final class StoreTests: XCTestCase {
    var folder: URL!
    var store: LibraryStore!
    var cal = Calendar(identifier: .gregorian)
    let fm = FileManager.default

    override func setUp() {
        cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        folder = fm.temporaryDirectory.appendingPathComponent("shortcut-store-\(UUID().uuidString)", isDirectory: true)
        store = LibraryStore(folder: folder)
    }
    override func tearDown() { try? fm.removeItem(at: folder) }

    func lib(_ names: String...) -> ShortcutLibrary {
        ShortcutLibrary(groups: names.map { AppGroup(name: $0, colour: "blue", shortcuts: [Shortcut(name: "s", keys: "A")]) })
    }
    func day(_ d: Int, hour: Int = 9) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: hour))! }
    func names(_ url: URL) -> [String] { LibraryStore.good(url)?.groups.map(\.name) ?? [] }

    func testSafetyCopyIsTheListBeforeAndTheDatedCopyIsTheListBeforeThatDaysFirstChange() throws {
        try store.save(lib("A"), now: day(16), calendar: cal)
        XCTAssertFalse(fm.fileExists(atPath: store.backup.path), "first save: nothing to copy yet")
        try store.save(lib("A", "B"), now: day(16, hour: 10), calendar: cal)
        try store.save(lib("A", "B", "C"), now: day(16, hour: 11), calendar: cal)
        XCTAssertEqual(names(store.file), ["A", "B", "C"])
        XCTAssertEqual(names(store.backup), ["A", "B"])
        XCTAssertEqual(store.dailyCopyNames(), ["shortcuts-2026-11-16.json"])
        XCTAssertEqual(names(store.copies.appendingPathComponent("shortcuts-2026-11-16.json")), ["A"])
        try store.save(lib("D"), now: day(17), calendar: cal)
        XCTAssertEqual(store.dailyCopyNames(), ["shortcuts-2026-11-17.json", "shortcuts-2026-11-16.json"])
        XCTAssertEqual(names(store.copies.appendingPathComponent("shortcuts-2026-11-17.json")), ["A", "B", "C"])
        XCTAssertEqual(store.load().library?.groups.map(\.name), ["D"])
    }

    func testAnEmptyOrUnreadableListIsPutAsideAndTheSafetyCopyIsUsed() throws {
        try store.save(lib("A"), now: day(16), calendar: cal)
        try store.save(lib("A", "B"), now: day(16, hour: 10), calendar: cal)
        for damaged in [#"{"version":1,"groups":[]}"#, "{}", "not a list at all", ""] {
            try Data(damaged.utf8).write(to: store.file)
            let loaded = store.load(now: day(18))
            XCTAssertEqual(loaded.source, .safetyCopy, damaged)
            XCTAssertEqual(loaded.library?.groups.map(\.name), ["A"])
            XCTAssertNotNil(loaded.setAside)
            XCTAssertFalse(fm.fileExists(atPath: store.file.path), "the damaged file was moved, not overwritten")
            try? fm.removeItem(at: loaded.setAside!)
        }
    }

    func testWithoutAGoodSafetyCopyTheNewestGoodDatedCopyIsUsed() throws {
        try store.save(lib("A"), now: day(15), calendar: cal)
        try store.save(lib("A", "B"), now: day(16), calendar: cal)      // dated copy 16 Nov = ["A"]
        try store.save(lib("A", "B", "C"), now: day(17), calendar: cal) // dated copy 17 Nov = ["A","B"]
        try Data("x".utf8).write(to: store.file)
        try Data("x".utf8).write(to: store.backup)
        let loaded = store.load()
        XCTAssertEqual(loaded.source, .dailyCopy("2026-11-17"))
        XCTAssertEqual(loaded.library?.groups.map(\.name), ["A", "B"])
    }

    func testAFirstStartHasNoListAndNothingIsPutAside() {
        let loaded = store.load()
        XCTAssertNil(loaded.library)
        XCTAssertEqual(loaded.source, .nothing)
        XCTAssertNil(loaded.setAside)
    }

    func testAnEmptyListNeverReplacesAGoodOne() throws {
        try store.save(lib("A"), now: day(16), calendar: cal)
        XCTAssertThrowsError(try store.save(ShortcutLibrary(), now: day(16), calendar: cal)) {
            XCTAssertEqual($0 as? LibraryStore.SaveError, .emptyOverGoodList)
        }
        XCTAssertEqual(names(store.file), ["A"])
    }

    func testADamagedListFileNeverOverwritesTheSafetyCopy() throws {
        try store.save(lib("A"), now: day(16), calendar: cal)
        try store.save(lib("A", "B"), now: day(16, hour: 10), calendar: cal)
        try Data("{}".utf8).write(to: store.file)
        try store.save(lib("Z"), now: day(16, hour: 11), calendar: cal)
        XCTAssertEqual(names(store.backup), ["A"])
        XCTAssertEqual(names(store.file), ["Z"])
    }

    func testOnlyTheNewestThirtyDatedCopiesAreKept() {
        let all = (1...35).map { String(format: "shortcuts-2026-%02d-%02d.json", $0 <= 30 ? 10 : 11, $0 <= 30 ? $0 : $0 - 30) }
        let gone = LibraryStore.namesToDelete(all.shuffled())
        XCTAssertEqual(gone.sorted(), (1...5).map { String(format: "shortcuts-2026-10-%02d.json", $0) })
        XCTAssertTrue(LibraryStore.namesToDelete(Array(all.prefix(30))).isEmpty)
    }

    func testAnExportReadsBackExactlyAsTheListWasLearnedAndRemovedIncluded() throws {
        var l = lib("A", "B", "C")
        Rules.tick(&l.groups[0].shortcuts[0], now: day(10))
        Rules.removeGroup(l.groups[1].id, in: &l, now: day(16))
        Rules.removeShortcut(l.groups[2].shortcuts[0].id, in: &l, now: day(16))
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = LibraryStore.exportName(day(16), calendar: cal)
        XCTAssertEqual(name, "AMS Shortcut Overview list 2026-11-16.json")
        let url = folder.appendingPathComponent(name)
        try LibraryStore.export(l, to: url)
        let back = try ShortcutLibrary.decode(Data(contentsOf: url))
        XCTAssertEqual(back.groups.map(\.name), ["A", "B", "C"])
        XCTAssertEqual(back.groups[0].shortcuts[0].learnedAt, day(10))
        XCTAssertNotNil(back.groups[1].removedAt)
        XCTAssertNotNil(back.groups[2].shortcuts[0].removedAt)
        XCTAssertEqual(back.groups.map(\.id), l.groups.map(\.id))
    }

    func testAFileThatIsNotAListIsRefused() throws {
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        let f = folder.appendingPathComponent("x.json")
        for bad in ["hello", "{}", #"{"groups":[]}"#, #"{"groups":[{"shortcuts":[{"name":"a","keys":"A"}]}]}"#, #"[1,2,3]"#] {
            try Data(bad.utf8).write(to: f)
            XCTAssertThrowsError(try LibraryStore.readList(at: f), bad) {
                XCTAssertEqual($0 as? LibraryStore.ImportError, .notAList)
            }
        }
        XCTAssertThrowsError(try LibraryStore.readList(at: folder.appendingPathComponent("missing.json")))
        try LibraryStore.export(lib("A", "B"), to: f)
        XCTAssertEqual(try LibraryStore.readList(at: f).groups.map(\.name), ["A", "B"])
    }

    func testBringingAListInKeepsTheListFromBeforeAsItsOwnCopy() throws {
        let mine = lib("Mine 1", "Mine 2", "Mine 3")
        try store.save(mine, now: day(16), calendar: cal)
        var other = lib("A", "B")
        Rules.tick(&other.groups[0].shortcuts[0], now: day(10))
        Rules.removeGroup(other.groups[1].id, in: &other, now: day(12))
        let before = try store.replace(with: other, current: mine, now: day(16, hour: 15), calendar: cal)
        XCTAssertEqual(before.lastPathComponent, "before-bringing-in-2026-11-16-150000.json")
        XCTAssertEqual(names(before), ["Mine 1", "Mine 2", "Mine 3"])
        let now = store.load().library!
        // (Dates are kept to the second in the file, so compare with the list as a file holds it.)
        XCTAssertEqual(now, try ShortcutLibrary.decode(other.encoded()), "the brought-in list reads back exactly")
        XCTAssertEqual(now.groups[0].shortcuts[0].learnedAt, day(10))
        XCTAssertNotNil(now.groups[1].removedAt)
        // The "before" copy is not a dated copy: never cleared after 30 days, never used for recovery.
        XCTAssertFalse(store.dailyCopyNames().contains(before.lastPathComponent))
        // Undo = bring the "before" copy in; the list being left is kept in turn.
        let back = try LibraryStore.readList(at: before)
        let second = try store.replace(with: back, current: now, now: day(16, hour: 16), calendar: cal)
        XCTAssertEqual(store.load().library?.groups.map(\.name), ["Mine 1", "Mine 2", "Mine 3"])
        XCTAssertEqual(names(second), ["A", "B"])
        XCTAssertThrowsError(try store.replace(with: ShortcutLibrary(), current: back, now: day(17), calendar: cal))
    }

    func testRemovedMarksSurviveSavingAndLoading() throws {
        var l = lib("A", "B")
        Rules.removeGroup(l.groups[1].id, in: &l, now: day(16))
        Rules.removeShortcut(l.groups[0].shortcuts[0].id, in: &l, now: day(16))
        try store.save(l, now: day(16), calendar: cal)
        let back = store.load().library!
        XCTAssertNotNil(back.groups[1].removedAt)
        XCTAssertNotNil(back.groups[0].shortcuts[0].removedAt)
        XCTAssertTrue(Rules.active(back.groups).isEmpty)
    }
}
