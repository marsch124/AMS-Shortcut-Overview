# AMS Shortcut Overview — specification

Version 0.1 (1), 16 Nov 2026. Mac only (macOS 15+), menu bar app without a Dock icon.

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

## Colours (day / night)
Seven: purple, coral, teal, blue, pink, amber, green. Day: pale fill (50), dark title (800), darker text (900), strong mark (600), white key caps. Night: deep fill (800), pale title (100), pale text (50), light mark (200/400), dark translucent key caps. New apps take the first colour no app uses yet. The main button always uses the strong day colour (full colour by day and night).

## Learning rule (ShortcutCore `Rules`)
- learning: never ticked → shown.
- tick while learning → `learnedAt` = now → hidden.
- 14 days after `learnedAt` → recheck → shown again at the top with "Recheck".
- tick on recheck → `recheckDone` → learned for good, never shown again.
- "Still learning" / "Bring back" → `learnedAt` = nil, `recheckDone` = false.

## Window (menu bar → "Shortcuts and settings…")
Five tabs, 560 × 520: Shortcuts (grouped by app, colour dot cycles colour, Move left/right reorders cards, Change per row, Add shortcut button, version), Learned (recheck date or "Learned for good", Bring back; empty-state text), Settings (show cards, shortcuts per card, open at login, Show in Finder, version), How it works, What's new.

## Editor (Cancel / Save, Escape = Cancel, Return = Save)
Fields: App (text + "Pick" menu of existing apps), What it does, Keys (text + ⌘ ⌥ ⌃ ⇧ buttons), "Looks like" preview. Errors: empty app, name or keys. Keys are tidied (one space between keys, single letters upper case). A new app name makes a new card. Existing shortcuts keep their place; Delete removes it (an app with no shortcuts left is removed).

## Menu bar menu
Add shortcut… (⌘N), Shortcuts and settings… (⌘,), Show cards on the desktop (tick), Version, Quit. Icon: the AMS Icon Library "keys" drawing as a template image.

## Data
`~/Library/Application Support/AMS Shortcut Overview/shortcuts.json` (ISO dates, tolerant decoding: unknown fields ignored, missing fields defaulted). Before each save the previous file is copied to `shortcuts-safety-copy.json`. Unreadable file → loads the safety copy; if none, the file is moved aside (`shortcuts-unreadable-<time>.json`), never overwritten. First start: `Starter.json` from the app (8 each for Obsidian, Raycast, Fusion). Personal lists never go into the repository.

## Start
Registers itself as a login item on the first start (switch in Settings). Refreshes "now" every hour so rechecks appear by themselves.

## Check links
`amsshortcuts://settings | add | day | night | system | snapshot` — snapshot writes `cards-<look>.png` (and the open windows) to `~/Library/Caches/com.schabbauer.AMSShortcutOverview/`.

## Build
`Tools/install.sh` (XcodeGen + xcodebuild, installs to `~/Applications`). Rules: `cd Core && swift test` (4 tests). Icon: `Tools/make-icon.py`.
