import XCTest
@testable import ShortcutCore

final class RulesTests: XCTestCase {
    let day: TimeInterval = 86_400
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func testTickHidesThenRechecksAfterTwoWeeksThenNoMoreRechecks() {
        var s = Shortcut(name: "Quick switcher", keys: "⌘ O")
        let g = { (s: Shortcut) in AppGroup(name: "Obsidian", colour: "purple", shortcuts: [s]) }
        XCTAssertEqual(Rules.visible(g(s), now: t0).count, 1)
        Rules.tick(&s, now: t0)
        XCTAssertEqual(Rules.visible(g(s), now: t0 + 13 * day).count, 0)
        XCTAssertEqual(Rules.status(s, now: t0 + 14 * day + 1), .recheck)
        Rules.tick(&s, now: t0 + 15 * day)
        XCTAssertEqual(Rules.visible(g(s), now: t0 + 400 * day).count, 0)
        Rules.bringBack(&s)
        XCTAssertEqual(Rules.status(s, now: t0), .learning)
    }

    func testRechecksShowFirst() {
        var a = Shortcut(name: "A", keys: "A"); Rules.tick(&a, now: t0)
        let b = Shortcut(name: "B", keys: "B")
        let g = AppGroup(name: "X", colour: "teal", shortcuts: [b, a])
        XCTAssertEqual(Rules.visible(g, now: t0 + 20 * day).map(\.name), ["A", "B"])
    }

    func testKeyPartsAndClean() {
        XCTAssertEqual(Rules.keyParts("⌘⇧F"), ["⌘", "⇧", "F"])
        XCTAssertEqual(Rules.keyParts("⌥ Space"), ["⌥", "Space"])
        XCTAssertEqual(Rules.cleanKeys("  ⌘  ⇧f "), "⌘ ⇧ F")
    }

    func testNextColourAndTolerantDecoding() throws {
        XCTAssertEqual(Rules.nextColour(used: ["purple", "coral"]), "teal")
        let lib = try ShortcutLibrary.decode(Data(#"{"groups":[{"name":"Obsidian","shortcuts":[{"name":"X","keys":"⌘ O","extra":1}]}]}"#.utf8))
        XCTAssertEqual(lib.groups[0].colour, "purple")
        XCTAssertEqual(lib.groups[0].shortcuts[0].keys, "⌘ O")
    }

    func testTodaysPickSameAllDayNewNextDayRechecksFirst() {
        var list = (0..<8).map { i in
            Shortcut(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(i)")!, name: "S\(i)", keys: "A")
        }
        Rules.tick(&list[5], now: t0 - 20 * day)
        let g = AppGroup(name: "X", colour: "teal", shortcuts: list)
        let morning = Rules.ordered(g, now: t0, daily: true).map(\.name)
        let later = Rules.ordered(g, now: t0 + 3600, daily: true).map(\.name)
        let tomorrow = Rules.ordered(g, now: t0 + day, daily: true).map(\.name)
        XCTAssertEqual(morning, later)
        XCTAssertNotEqual(morning, tomorrow)
        XCTAssertEqual(morning.first, "S5")
        XCTAssertEqual(Set(morning).count, 8)
        XCTAssertEqual(Rules.ordered(g, now: t0, daily: false).map(\.name), ["S5", "S0", "S1", "S2", "S3", "S4", "S6", "S7"])
    }

    func testLearnedThisWeekCountsOnlyTheCurrentWeek() {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2; cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        let wed = cal.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 12))!
        let mon = cal.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 0, minute: 5))!
        let lastSun = cal.date(from: DateComponents(year: 2026, month: 11, day: 15, hour: 23))!
        let g = AppGroup(name: "A", colour: "blue", shortcuts: [
            Shortcut(name: "a", keys: "A", learnedAt: mon),
            Shortcut(name: "b", keys: "B", learnedAt: wed, recheckDone: true),
            Shortcut(name: "c", keys: "C", learnedAt: lastSun),
            Shortcut(name: "d", keys: "D")])
        XCTAssertEqual(Rules.learnedThisWeek([g], now: wed, calendar: cal), 2)
    }

    func testAddReadyMadeSkipsExistingNameAndAvoidsTakenColour() {
        var lib = ShortcutLibrary(groups: [AppGroup(name: "obsidian", colour: "blue", shortcuts: [Shortcut(name: "x", keys: "X")])])
        let finder = AppGroup(name: "Finder", colour: "blue", shortcuts: [Shortcut(name: "New window", keys: "⌘ N", learnedAt: t0)])
        XCTAssertFalse(Rules.addReadyMade(AppGroup(name: "Obsidian", colour: "purple"), to: &lib))
        XCTAssertTrue(Rules.addReadyMade(finder, to: &lib))
        XCTAssertFalse(Rules.addReadyMade(finder, to: &lib))
        XCTAssertEqual(lib.groups.count, 2)
        XCTAssertEqual(lib.groups[1].colour, "purple")
        XCTAssertNil(lib.groups[1].shortcuts[0].learnedAt)
        XCTAssertNotEqual(lib.groups[1].shortcuts[0].id, finder.shortcuts[0].id)
    }

    // MARK: 0.4 — Removed, weeks in a row, rows of cards

    func testRemovedShortcutAndAppAreHiddenNotDeletedAndComeBackAsTheyWere() {
        var a = Shortcut(name: "A", keys: "A"); Rules.tick(&a, now: t0)
        let b = Shortcut(name: "B", keys: "B")
        var lib = ShortcutLibrary(groups: [AppGroup(name: "Finder", colour: "blue", shortcuts: [a, b]),
                                           AppGroup(name: "Mail", colour: "pink", shortcuts: [Shortcut(name: "C", keys: "C")])])
        Rules.removeShortcut(b.id, in: &lib, now: t0)
        XCTAssertEqual(Rules.active(lib.groups)[0].shortcuts.map(\.name), ["A"])
        XCTAssertEqual(Rules.removedShortcuts(lib.groups)[0].shortcuts.map(\.name), ["B"])
        XCTAssertEqual(lib.groups[0].shortcuts.count, 2, "nothing is deleted")
        Rules.bringBackShortcut(b.id, in: &lib)
        XCTAssertTrue(Rules.removedShortcuts(lib.groups).isEmpty)

        let finder = lib.groups[0].id
        Rules.removeGroup(finder, in: &lib, now: t0)
        XCTAssertEqual(Rules.active(lib.groups).map(\.name), ["Mail"])
        XCTAssertEqual(Rules.removedApps(lib.groups).first?.shortcuts.count, 2)
        lib.groups[1].colour = "blue"                      // Mail takes Finder's colour meanwhile
        Rules.bringBackGroup(finder, in: &lib)
        XCTAssertEqual(Rules.active(lib.groups).map(\.name), ["Finder", "Mail"])
        XCTAssertEqual(lib.groups[0].shortcuts[0].learnedAt, t0, "learned state kept")
        XCTAssertEqual(lib.groups[0].colour, "purple", "next free colour instead of a clash")
    }

    func testReadyMadeBringsARemovedAppBackInsteadOfASecondCopy() {
        var mine = Shortcut(name: "My own", keys: "⌘ J"); Rules.tick(&mine, now: t0)
        var lib = ShortcutLibrary(groups: [AppGroup(name: "Safari", colour: "green", shortcuts: [mine])])
        Rules.removeGroup(lib.groups[0].id, in: &lib, now: t0)
        let ready = AppGroup(name: "Safari", colour: "green", shortcuts: [Shortcut(name: "New tab", keys: "⌘ T")])
        XCTAssertTrue(Rules.addReadyMade(ready, to: &lib))
        XCTAssertEqual(lib.groups.count, 1)
        XCTAssertEqual(Rules.active(lib.groups)[0].shortcuts.map(\.name), ["My own"])
        XCTAssertEqual(lib.groups[0].shortcuts[0].learnedAt, t0)
    }

    func testAnAppWithEveryShortcutRemovedIsOffTheListAndComesBackWhole() {
        let a = Shortcut(name: "A", keys: "A")
        var lib = ShortcutLibrary(groups: [AppGroup(name: "X", colour: "teal", shortcuts: [a])])
        Rules.removeShortcut(a.id, in: &lib, now: t0)
        XCTAssertTrue(Rules.active(lib.groups).isEmpty)
        Rules.bringBackGroup(lib.groups[0].id, in: &lib)
        XCTAssertEqual(Rules.active(lib.groups)[0].shortcuts.count, 1)
    }

    func testMoveStepsOverRemovedApps() {
        let one = { (n: String) in AppGroup(name: n, colour: "blue", shortcuts: [Shortcut(name: n, keys: "A")]) }
        var lib = ShortcutLibrary(groups: [one("A"), one("B"), one("C")])
        Rules.removeGroup(lib.groups[1].id, in: &lib, now: t0)
        Rules.moveGroup(lib.groups[0].id, by: 1, in: &lib)
        XCTAssertEqual(Rules.active(lib.groups).map(\.name), ["C", "A"])
        XCTAssertEqual(lib.groups.count, 3)
        Rules.moveGroup(lib.groups[0].id, by: -1, in: &lib)   // already first: stays
        XCTAssertEqual(Rules.active(lib.groups).map(\.name), ["C", "A"])
    }

    func testWeeksInARow() {
        var cal = Calendar(identifier: .gregorian); cal.firstWeekday = 2; cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        let d = { (m: Int, day: Int) in cal.date(from: DateComponents(year: 2026, month: m, day: day, hour: 12))! }
        let g = { (dates: [Date]) in AppGroup(name: "A", colour: "blue", shortcuts: dates.map { Shortcut(name: "s", keys: "A", learnedAt: $0) }) }
        let wed = d(11, 18)                                    // week of Mon 16 Nov 2026
        XCTAssertEqual(Rules.weekStreak([g([])], now: wed, calendar: cal), 0)
        XCTAssertEqual(Rules.weekStreak([g([d(11, 17)])], now: wed, calendar: cal), 1)
        // 17 Nov, 9 Nov (Mon), 8 Nov (Sun) and 28 Oct fall in four weeks one after the other.
        XCTAssertEqual(Rules.weekStreak([g([d(11, 17), d(11, 9), d(11, 8), d(10, 28)])], now: wed, calendar: cal), 4)
        // Nothing yet this week: last week's run still counts.
        XCTAssertEqual(Rules.weekStreak([g([d(11, 12), d(11, 3)])], now: wed, calendar: cal), 2)
        // A full week with nothing ends the run.
        XCTAssertEqual(Rules.weekStreak([g([d(11, 3), d(10, 28)])], now: wed, calendar: cal), 0)
        XCTAssertEqual(Rules.weekStreak([g([d(11, 17), d(11, 3)])], now: wed, calendar: cal), 1)
    }

    func testCardsThatDoNotFitGoToARowAboveAndTheFirstKeepTheirPlace() {
        XCTAssertEqual(Rules.cardsPerRow(width: 1700), 6)      // 16-inch MacBook Pro
        XCTAssertEqual(Rules.cardsPerRow(width: 1484), 5)      // 14-inch
        XCTAssertEqual(Rules.cardsPerRow(width: 100), 1)
        XCTAssertEqual(Rules.cardRows([1, 2, 3, 4, 5], perRow: 6), [[1, 2, 3, 4, 5]])
        XCTAssertEqual(Rules.cardRows([1, 2, 3, 4, 5, 6, 7, 8], perRow: 6), [[1, 2, 3, 4, 5, 6], [7, 8]])
        XCTAssertEqual(Rules.cardRows([Int](), perRow: 6).count, 0)
    }
}
