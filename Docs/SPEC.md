# AMS Shortcut Overview — specification

Version 0.3.1 (4), 16 Nov 2026. Mac only (macOS 15+), menu bar app without a Dock icon.

## Purpose
Help learn keyboard shortcuts by keeping the ones still being learned in sight on the desktop, one colour card per app.

## Desktop cards
- One borderless, non-activating panel at desktop-icon level + 1 (below every normal window), on all Spaces, never key.
- Placed bottom centre of the main screen's visible area, 14 pt above its bottom (above the Dock); width capped at screen width − 24 pt. Re-placed on every list change and screen change.
- Cards side by side, 10 pt apart, 260 pt wide, 12 pt corners. Only apps with at least one visible shortcut get a card; the panel hides when there are none or "Show cards" is off.
- Card: app name (headline, title colour), "N learned" (caption, when N > 0), a drawn + button (adds a shortcut for that app). Rows: drawn tick circle · name (callout, one line) · optional "Recheck" capsule · key caps.
- Rows shown: rechecks first, then learning ones, in list order, up to "Shortcuts per card" (default 6, 3–12); the rest as "+N more".
- Tick: circle shows a drawn check, the name is struck through, 0.6 s later the change is saved and the row leaves.
- Right-click a row: "Change…", "Still learning" (rechecks only), "I know it".
- Key caps: keys split on spaces; modifier symbols ⌘ ⌥ ⌃ ⇧ written together are split too. Rounded 12 pt medium, 4 pt corners.

## Today's shortcuts (switch "Today's shortcuts", off by default)
- Off: rows in list order (rechecks first). On: `Rules.ordered(group, now:, daily:)` with `daily: true` — rechecks first (list order), then the learning shortcuts sorted by a stable hash of the day string (`yyyy-MM-dd` of `now`) combined with the shortcut's `id`. Same day → same order all day, on every launch; a new day → a new order. The hash is stable (not Swift's per-launch `hashValue`).
- The card shows up to "Shortcuts per card" rows of that order; ticking one moves the next of the pick up; the rest is "+N more".
- The card header shows "Today" next to the app name while the switch is on.
- "Now" is refreshed every hour and on wake from sleep (`NSWorkspace.didWakeNotification`), so the pick changes after midnight by itself.
- The list order stored in the file and shown on the Shortcuts page is never changed by this switch.

## Quiz me (switch "Quiz me", off by default)
- On: every key cap on a card is drawn as a blank cap with a "?" (same size as the real cap, so the number of keys is visible).
- Pointing at a row (hover) shows the real keys; moving away hides them. Clicking the hidden keys pins them shown until clicked again (pinned state is per row, kept in memory only, cleared when the switch goes off).
- Tick, right-click menu and + button work as usual.
- Both switches are stored in the app's settings (UserDefaults), shown in Settings and in the menu bar menu, and always in sync.

## Colours (day / night)
Seven: purple, coral, teal, blue, pink, amber, green. Day: pale fill (50), dark title (800), darker text (900), strong mark (600), white key caps. Night: deep fill (800), pale title (100), pale text (50), light mark (200/400), dark translucent key caps. New apps take the first colour no app uses yet. The main button always uses the strong day colour (full colour by day and night).

## Learning rule (ShortcutCore `Rules`)
- learning: never ticked → shown.
- tick while learning → `learnedAt` = now → hidden.
- 14 days after `learnedAt` → recheck → shown again at the top with "Recheck".
- tick on recheck → `recheckDone` → no more rechecks; hidden from the card but KEPT in the list (Shortcuts + Learned pages, "Learned, no more rechecks"); "Bring back" restores it. Ticking never deletes; only Delete (editor) and Remove (app) delete.
- "Still learning" / "Bring back" → `learnedAt` = nil, `recheckDone` = false.

## Learned this week (0.3)
- `Rules.learnedThisWeek(groups, now:, calendar:)` counts the shortcuts whose `learnedAt` lies in the same week as `now`, using `calendar.dateInterval(of: .weekOfYear, for: now)`. The app's calendar is the Swedish one: the week starts on Monday and the count restarts at 0 each Monday.
- A shortcut counts for the week of its first tick, whatever happened after: a later recheck tick (`recheckDone`) keeps `learnedAt`, so it still counts; "Bring back" / "Still learning" clears `learnedAt`, so it no longer counts.
- Shown in the menu bar menu ("Learned this week: N") and on the Learned page (see below). "Now" is the same hourly-refreshed value as for rechecks.

## Window (menu bar → "Shortcuts and settings…")
Five tabs, 560 × 520: Shortcuts (grouped by app, colour dot cycles colour, Move left/right reorders cards, Remove per app, Change per row, "Add shortcut" and "Add ready-made app" buttons at the bottom, version), Learned (first line "This week: N learned · M learned in all", N = `Rules.learnedThisWeek`, M = all shortcuts currently on the page; then recheck date or "Learned for good", Bring back; empty-state text), Settings (show cards, shortcuts per card, Today's shortcuts, Quiz me, open at login, Show in Finder, version), How it works, What's new.

## Ready-made apps and Remove (0.3)
- "Add ready-made app" (bottom of the Shortcuts page, next to "Add shortcut") is a menu of the ready-made apps from `Starter.json` that are not on the list yet (name compared ignoring case). Picking one calls `Rules.addReadyMade(_ group:, to: library)`: skipped if an app of that name is already there (any case); gives the group and its shortcuts fresh ids; colour = the group's own colour if free, else the next free colour. If all are on the list the button is greyed out and its tooltip says "Every ready-made app is on your list already".
- "Remove" (app heading, next to Move left / Move right) asks "Remove <app> and its N shortcuts?" with Cancel and Remove. Remove deletes the group and all its shortcuts, learned ones included, and saves (the safety copy of the previous file is made as for every save). A removed ready-made app can be added again, fresh (nothing learned).

## Editor (Cancel / Save, Escape = Cancel, Return = Save)
Fields: App (text + "Pick" menu of existing apps), What it does, Keys (text + ⌘ ⌥ ⌃ ⇧ buttons), "Looks like" preview. Errors: empty app, name or keys. Keys are tidied (one space between keys, single letters upper case). A new app name makes a new card. Existing shortcuts keep their place; Delete removes it (an app with no shortcuts left is removed).

## Menu bar menu
Add shortcut… (⌘N), Shortcuts and settings… (⌘,), Show cards on the desktop (tick), Today's shortcuts (tick), Quiz me (tick), "Learned this week: N" (grey, disabled info line, just above Version), Version, Quit. Icon: the AMS Icon Library "keycap" drawing (a keyboard key, 24-point grid, 1.9 stroke, round ends, no fill) as a template image; the app icon is the same keycap, white on a flat calm background. Replaces the old door-key "keys" icon of 0.1.

## Data
`~/Library/Application Support/AMS Shortcut Overview/shortcuts.json` (ISO dates, tolerant decoding: unknown fields ignored, missing fields defaulted). Before each save the previous file is copied to `shortcuts-safety-copy.json`. Unreadable file → loads the safety copy; if none, the file is moved aside (`shortcuts-unreadable-<time>.json`), never overwritten. `Starter.json` in the app holds all 6 ready-made apps, 8 shortcuts each: Obsidian (purple), Raycast (coral), Fusion (teal), Finder (blue), Xcode (amber), Safari (green). First start (no file): the list is the first 5 of them (Obsidian, Raycast, Fusion, Finder, Xcode; 40 shortcuts); Safari is only added from "Add ready-made app". One-time 0.3 addition: on the first start of 0.3 with an existing list, Finder and Xcode are added through `Rules.addReadyMade` (so only if no app of that name exists; nothing else changes), guarded by the UserDefaults flag `addedFinderXcode03`, set after the first run so it never repeats (a removed Finder or Xcode stays removed). Personal lists never go into the repository.

## Start
Registers itself as a login item on the first start (switch in Settings). Refreshes "now" every hour so rechecks appear by themselves.

## Check links
`amsshortcuts://settings | add | day | night | system | snapshot` — snapshot writes `cards-<look>.png` (and the open windows) to `~/Library/Caches/com.schabbauer.AMSShortcutOverview/`.

## Build
`Tools/install.sh` (XcodeGen + xcodebuild, installs to `~/Applications`). Rules: `cd Core && swift test` (7 tests: the 5 earlier ones, which include the daily order, plus one for `Rules.learnedThisWeek` and one for `Rules.addReadyMade`). Icon: `Tools/make-icon.py`.
