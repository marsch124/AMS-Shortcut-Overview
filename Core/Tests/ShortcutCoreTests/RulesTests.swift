import XCTest
@testable import ShortcutCore

final class RulesTests: XCTestCase {
    let day: TimeInterval = 86_400
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func testTickHidesThenRechecksAfterTwoWeeksThenGoneForGood() {
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
}
