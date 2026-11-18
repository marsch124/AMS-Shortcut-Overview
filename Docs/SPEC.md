# AMS Shortcut Overview — specification

Version 0.6.2 (11), 18 Nov 2026. Mac only (macOS 15+), menu bar app without a Dock icon.

## Purpose
Help learn keyboard shortcuts by keeping the ones still being learned in sight on the desktop, one colour card per app.

## Desktop cards
- One borderless, non-activating panel at desktop-icon level + 1 (below every normal window), on all Spaces, never key.
- Placed bottom centre of the main screen's visible area, 14 pt above its bottom (above the Dock); width capped at screen width − 24 pt. Re-placed on every list change and screen change.
- Cards side by side, 10 pt apart, 260 pt wide, 12 pt corners. Rows (0.4): the number of cards per row is the most that fit in the panel width (260 pt each + 10 pt gaps; 6 on a 16-inch MacBook Pro). Extra cards go into a second row above the first, then a third, and so on; before 0.4 all cards were in one row and the outer ones were cut off at both edges. The first cards (in list order) stay in the bottom row; the newest apps are on top. The per-row count follows the screen's width and is recomputed on every screen change (screen connected or removed). Only apps with at least one visible shortcut get a card; the panel hides when there are none or "Show cards" is off.
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
- tick on recheck → `recheckDone` → no more rechecks; hidden from the card but KEPT in the list (Shortcuts + Learned pages, "Learned, no more rechecks"); "Bring back" restores it. Ticking never deletes. Nothing is ever deleted (0.4): Remove (editor and app) only hides, see "Removed page".
- Time of a tick (fixed in 0.5.1): `learnedAt` (and `removedAt`) is the exact moment of the click. Before 0.5.1 it was the app's "now", which only moves with the hourly clock check, so it could be up to one hour too early; two ticks a minute apart both got the app's start time. Now the recheck is 14 days after the real moment, and a tick just after Monday midnight counts in the right week.
- "Still learning" / "Bring back" → `learnedAt` = nil, `recheckDone` = false.

## Learned this week (0.3)
- `Rules.learnedThisWeek(groups, now:, calendar:)` counts the shortcuts whose `learnedAt` lies in the same week as `now`, using `calendar.dateInterval(of: .weekOfYear, for: now)`. The app's calendar is the Swedish one: the week starts on Monday and the count restarts at 0 each Monday.
- A shortcut counts for the week of its first tick, whatever happened after: a later recheck tick (`recheckDone`) keeps `learnedAt`, so it still counts; "Bring back" / "Still learning" clears `learnedAt`, so it no longer counts.
- Shown in the menu bar menu ("Learned this week: N") and on the Learned page (see below). "Now" is the same hourly-refreshed value as for rechecks.

## Weeks in a row (0.4)
- The count of consecutive weeks (Monday to Sunday, Swedish calendar) in which at least one shortcut has a `learnedAt`. Counted from the `learnedAt` dates, so "Bring back" / "Still learning" (which clear `learnedAt`) take a shortcut out of it.
- The current week does not break the run while it has no tick yet; the run ends only when a full week passes with nothing learned. A run is shown from 2 weeks up.
- Menu bar menu: "Learned this week: 3 · 2 weeks in a row" (below 2 weeks: "Learned this week: 3" as before). Learned page first line: "This week: 3 learned · 12 learned in all · 2 weeks in a row" (the last part only from 2 weeks).

## Window (menu bar → "Shortcuts and settings…")
Six tabs (before 0.4: five), 560 × 520, in this order: Shortcuts, Learned, Removed, Settings, How it works, What's new. Shortcuts (grouped by app, colour dot cycles colour, Move left/right reorders cards, Remove per app (hides it, see below), Change per row, "Add shortcut" and "Add ready-made app" buttons at the bottom, version), Learned (first line "This week: N learned · M learned in all", N = `Rules.learnedThisWeek`, M = all shortcuts currently on the page; then recheck date or "Learned, no more rechecks", Bring back; empty-state text; "· W weeks in a row" added from 2 weeks), Removed (see below), Settings (show cards, shortcuts per card, Today's shortcuts, Quiz me, open at login (0.6.2: a small grey line under the switch, "While this is on, the app also comes back by itself if it ever stops unexpectedly."), Show in Finder, "A copy to keep anywhere" with "Export my list…" (0.5, see "Export my list"), version), How it works, What's new.

## Removed page — nothing is ever deleted (0.4)
- Before 0.4 the editor's "Delete" and the app's "Remove" took shortcuts out of the list completely. Now there is no way to delete a shortcut: the editor button is "Remove", and it and the app's "Remove" only hide. Each shortcut and each group carries a removed flag; removed things stay in `shortcuts.json` with all their fields (`learnedAt`, `recheckDone`, colour).
- Removing an app asks "Remove <app> from the desktop?" with the note "The card and its N shortcuts move to the Removed page. Bring them back from there any time." (Cancel / Remove). "Remove" is the coloured main button and the Return key presses it; Escape is Cancel (seen with the window in front; while another app is in front the Mac draws both buttons grey).
- Removed page: first line "Nothing is ever deleted. Bring back what you want to see again." Removed apps are listed with their shortcuts and one button "Bring back app"; single removed shortcuts are listed under their app's name, each with "Bring back". Empty: "Nothing removed".
- Bring back restores exactly as it was (learned state, recheck date, colour). If another app took the colour meanwhile, the next free colour is used.
- Stored as a date, `removedAt`, on the shortcut or on the group (absent = on the list). Every page, card and count works on `Rules.active(groups)`: groups without `removedAt`, each without its removed shortcuts. The two learned-this-week counts and the weeks in a row count every shortcut, removed ones too.
- An app whose shortcuts were all removed one by one is off the Shortcuts page and the desktop (it has nothing to show); its shortcuts stand on the Removed page under its name, each with "Bring back". Bringing a whole app back when all its shortcuts were removed one by one brings all of them back.
- "Move left" / "Move right" step over removed apps.
- "Add ready-made app": a ready-made app that was removed earlier is brought back (the user's own one, as it was) instead of adding a second copy. Typing a removed app's name in the editor also brings that app's card back.
- Removed shortcuts and apps do not count for cards, "Learned this week", weeks in a row or the Learned page.

## Ready-made apps and Remove (0.3, changed in 0.4)
- "Add ready-made app" (bottom of the Shortcuts page, next to "Add shortcut") is a menu of the ready-made apps from `Starter.json` that are not on the list yet (name compared ignoring case). Picking one calls `Rules.addReadyMade(_ group:, to: library)`: skipped if an app of that name is already there (any case); gives the group and its shortcuts fresh ids; colour = the group's own colour if free, else the next free colour. If all are on the list the button is greyed out and its tooltip says "Every ready-made app is on your list already".
- "Remove" (app heading, next to Move left / Move right) asks first (wording under "Removed page" above). As changed in 0.4: Remove no longer deletes; it moves the group and its shortcuts to the Removed page, and saves (the safety copies are made as for every save). The confirmation wording is under "Removed page" above. "Add ready-made app" is greyed out only when all 8 are on the list (a removed one is not on the list, so it is offered there; choosing it brings the user's own one back).

## Editor (Cancel / Save, Escape = Cancel, Return = Save)
Fields: App (text + "Pick" menu of existing apps), What it does, Keys (text + ⌘ ⌥ ⌃ ⇧ buttons), "Looks like" preview. Errors: empty app, name or keys. Keys are tidied (one space between keys, single letters upper case). A new app name makes a new card. Existing shortcuts keep their place; Remove (was "Delete" before 0.4) hides the shortcut on the Removed page (an app with no visible shortcuts left shows no card but is not removed; its shortcuts stay on the Shortcuts page). Typing a removed app's name brings that app's card back.

## Menu bar menu
Status item `autosaveName` "shortcutOverview"; first start writes `NSStatusItem Preferred Position shortcutOverview` = 222 (pt from the right; Tidy Bar drawer 40, Mic Check 177, Deck Mate 266, Tidy Bar line 380) so the icon is on the always-shown side and right of the notch. ⌘-drag moves are remembered.
Red line "Could not save your list" at the top while the last save failed (0.4). Add shortcut… (⌘N), Shortcuts and settings… (⌘,), Show cards on the desktop (tick), Today's shortcuts (tick), Quiz me (tick), "Learned this week: N" (with " · W weeks in a row" from 2 weeks; grey, disabled info line, just above Version), Version, Quit. Icon: the AMS Icon Library "keycap" drawing (a keyboard key, 24-point grid, 1.9 stroke, round ends, no fill) as a template image; the app icon is the same keycap, white on a flat calm background. Replaces the old door-key "keys" icon of 0.1.

## Data
`~/Library/Application Support/AMS Shortcut Overview/shortcuts.json` (ISO dates, tolerant decoding: unknown fields ignored, missing fields defaulted). Removed flags are stored in the file (0.4). `Starter.json` in the app holds all 8 ready-made apps, 8 shortcuts each: Obsidian (purple), Raycast (coral), Fusion (teal), Finder (blue), Xcode (amber), Safari (green), Mail (pink), Notes (amber); Mail and Notes were confirmed on Apple's own pages, and all keys were re-checked against the makers' own pages in 0.4. Safety and recovery: see "Safety copies and recovery". First start (no file): the list is the first 5 of them (Obsidian, Raycast, Fusion, Finder, Xcode; 40 shortcuts); Safari, Mail and Notes are only added from "Add ready-made app". One-time 0.3 addition: on the first start of 0.3 with an existing list, Finder and Xcode are added through `Rules.addReadyMade` (so only if no app of that name exists; nothing else changes), guarded by the UserDefaults flag `addedFinderXcode03`, set after the first run so it never repeats (a removed Finder or Xcode stays removed). Personal lists never go into the repository.

## Safety copies and recovery (0.4)
- Before each save the previous file is copied to `shortcuts-safety-copy.json` (one copy: the list before the last change).
- New: one dated copy per day in the folder `Safety copies` next to the list (Settings → "Show in Finder"): the list as it was before that day's first change, named `shortcuts-yyyy-MM-dd.json`. Kept for 30 days; older ones are cleared away.
- A list file that cannot be read, or that has no apps at all (the app only hides, so a real list is never empty), is treated as damaged: the file is moved aside as `shortcuts-unreadable-<time>.json` (never overwritten) and the list is loaded from the safety copy; if that is no good, from the newest good dated copy. Before 0.4 a file with no apps was accepted and could later overwrite the good list. The window shows an amber line saying where the list was restored from.
- The app refuses to save an empty list over a good one.
- A failed save shows a red line "Could not save your list" at the top of the window and in the menu bar menu; the save is retried every hour and with the next change, and the line goes away when it worked (before 0.4 nothing was shown).
- Environment variable `AMS_SHORTCUTS_FOLDER` points the app at another folder for its list (an internal aid for checking screens with a test list; nothing a user needs). On a test list (0.5.1) the app also shows as a normal app with a Dock icon, so that click checks can find it; the normal app never does.

## Export my list (0.5)
- Before 0.5 the list lived only in `shortcuts.json` and the safety copies next to it. Now Settings has a new row "A copy to keep anywhere" with the button "Export my list…", directly under the row "Your list is kept in" / "Show in Finder".
- The button opens the standard save panel (`NSSavePanel`) with the title "Export my list". The name is pre-filled as `AMS Shortcut Overview list yyyy-MM-dd.json` (today's date). The user chooses the place (iCloud Drive, Dropbox, a USB stick, anywhere). Cancel closes the panel and writes nothing. Saving twice under the same name asks before replacing, as the panel always does.
- The file holds the whole list: every app and every shortcut with all fields (learned date, recheck done, colour, order) and the removed ones (`removedAt`) too. Its form is the same as `shortcuts.json` (same encoder, ISO dates), so it reads back exactly as the list was.
- After a successful save a grey caption under the row reads, for example, "Last export: 16 Nov 2026 at 14:05 · 5 apps and 40 shortcuts" (0.6.1; before: "· 5 apps, 40 shortcuts" with removed ones counted in). When anything is on the Removed page the counts end ", plus … on the Removed page" (see "Counts" in the next section). A caption written by an earlier version keeps its old words until the next export. The date and counts are stored in the app's settings (UserDefaults), so the line stays after a restart. If writing fails, a red caption "Could not export: <reason>" shows instead.
- Exporting only reads the list: it changes nothing in the list, makes no safety copy and can be done as often as wanted.
- Not in 0.5: reading an export back in. That came in 0.6 (next section).

## Bring a list back in (0.6)
- Before 0.6 an export could not be read back. Now Settings has a new row "Bring an exported list back" with the button "Bring a list back in…", directly under the row "A copy to keep anywhere" (Export my list…).
- The button opens the standard open panel (`NSOpenPanel`) titled "Bring a list back in". The user picks a file exported earlier (name like `AMS Shortcut Overview list 2026-11-16.json`). Cancel closes the panel and nothing changes.
- The file is checked first. If it is not a list from this app, holds no apps, or an app in it has no name, a red caption under the row reads "This file is not a list from AMS Shortcut Overview. Nothing was changed." and nothing changes.
- If the file is good, the app asks first: "Replace your list with this one?" The note names the file and gives both counts, for example: The file "AMS Shortcut Overview list 2026-11-16.json" holds 8 apps and 64 shortcuts. Your list now holds 5 apps and 40 shortcuts. It is kept as a safety copy first, so you can undo this. Buttons: "Replace my list" (coloured main button, Return) and "Cancel" (Escape). Counts read as in "Counts (0.6.1)" below. Unchanged in 0.6.1.
- "Replace my list" does three things in this order: (1) it saves the current list as its own file in the "Safety copies" folder, named `before-bringing-in-yyyy-MM-dd-HHmmss.json` (date and time), for example `before-bringing-in-2026-11-16-152233.json`; if that copy cannot be written, nothing is replaced; (2) it replaces the list with the one from the file: every app and shortcut, learned state, recheck dates, colours, order and the Removed page exactly as at export; (3) the cards on the desktop change at once.
- It replaces, it does not mix: shortcuts added after the export are not in the brought-in list. They are in the "before" copy.
- Afterwards a grey caption under the row reads, for example: Brought in 8 apps and 64 shortcuts. Your list from before is kept, press Undo to get it back. (0.6.1; before: "Brought in 8 apps, 64 shortcuts. …"; ", plus … on the Removed page" follows the counts when there is any.)
- "Undo": after a bring-in a second button "Undo" appears in the same row, left of "Bring a list back in…". The list being left is kept as a new "before" copy, so Undo can itself be undone. The button stays after a restart, as long as that "before" file exists. What Undo does underneath is unchanged (it replaces, keeps the list being left as a new "before" copy, never mixes). Its tooltip is "Puts back the list you had before. It asks first." (0.6.1; before: "Puts back the list you had before the last bring-in. It asks first.").
- Undo's own question (0.6.1). Before (0.6), Undo asked the same question as a bring-in: title "Replace your list with this one?", a note naming the file (e.g. "before-bringing-in-2026-11-16-153241.json") and the button "Replace my list". Now: title "Put your earlier list back?"; note, for example: This is the list you had before the last bring-in: 5 apps and 40 shortcuts. Your list now holds 8 apps and 64 shortcuts. It is kept as a safety copy first, so this can be undone too. Buttons: "Put it back" (coloured main button, Return) and "Cancel" (Escape). No file name is shown.
- A second Undo (undoing the Undo) starts the note "This is the list you had before the last Undo: …" instead of "…before the last bring-in: …". The app keeps a setting `lastBeforeWasUndo` so the note says "bring-in" or "Undo" truthfully.
- The grey caption after an Undo (0.6.1) reads "Your earlier list is back: 5 apps and 40 shortcuts. The list you had just now is kept, press Undo to return to it." Before: "Brought in 5 apps, 40 shortcuts. Your list from before is kept, press Undo to get it back."
- If the earlier list's copy cannot be read, the red caption reads "Your earlier list could not be read. Nothing was changed." (0.6.1; before: "This file is not a list from AMS Shortcut Overview. Nothing was changed.").
- The `before-bringing-in-…` copies stay until the user clears them away; the 30-day clearing of the dated copies does not touch them, and the app never uses them by itself (not for repairing a damaged list).
- Counts (0.6.1). Before, every count included the apps and shortcuts on the Removed page without saying so; when two lists differed only in what was on the Removed page, the question showed the same numbers twice (seen: "holds 8 apps and 65 shortcuts. Your list now holds 8 apps and 65 shortcuts"). Now a count gives what is on the list and, only when there is any, what is on the Removed page separately: "7 apps and 57 shortcuts, plus 1 app and 8 shortcuts on the Removed page"; with only single removed shortcuts "8 apps and 62 shortcuts, plus 3 shortcuts on the Removed page"; with nothing removed "5 apps and 40 shortcuts" (as before). One is written "1 app" / "1 shortcut".
- How counts are made (0.6.1): a rule in the core, `Rules.counts(groups)`. On the list = `Rules.active` (its apps and their shortcuts). Removed page = the `Rules.removedApps` count, and all shortcuts minus the ones on the list, so it covers every shortcut that stands on the Removed page (those of removed apps and single removed ones). Its words come from `Rules.countWords(groups)`. The same words are used in all four places, so they always agree: the bring-in question, the Undo question, the grey "Brought in …" caption and the grey "Last export: …" caption.
- Tests: 27 (0.6.2; two more: of two copies the earlier one stays, and the keeper's start order). Before: 25 (0.6.1; 0.6 had 24, before 0.6 there were 22). In 0.6.1 one more: the counts tell the list and the Removed page apart. The two new ones of 0.6 check that a file that is not a list is refused, and that replacing keeps the list from before as its own copy and the new list reads back exactly.
- Checked with real clicks (0.6.1), on a separate test list (8 apps, 65 shortcuts, Safari on the Removed page), with the app in front: the bring-in question read "holds 8 apps and 65 shortcuts. Your list now holds 7 apps and 57 shortcuts, plus 1 app and 8 shortcuts on the Removed page", "Replace my list" coloured; the caption read "Brought in 8 apps and 65 shortcuts. …"; Undo asked "Put your earlier list back?" with no file name, both counts and "Put it back" coloured; "Put it back" restored the earlier list whole (8 groups, 65 shortcuts, Safari removed) and made a second "before" copy; the caption read "Your earlier list is back: 7 apps and 57 shortcuts, plus 1 app and 8 shortcuts on the Removed page. …"; a second Undo read "before the last Undo"; Cancel changed nothing. Not tried: the Return and Escape keys themselves (the buttons were clicked), the red caption for an unreadable earlier list, the new words in the "Last export" caption.

## Checked with real clicks (0.5.1)
Before 0.5.1 the screens were only checked from pictures. For 0.5.1 the app was tried with real clicks and mouse presses on a separate test list (the real list was not touched). Tried and working:
- A tick on a desktop card, once as a button press and once as a real mouse press: the row is crossed out and leaves the card, the card counts "1 learned" then "2 learned", and the list file holds it.
- Quiz me: a click on the "?" keys of a row shows the real keys of that row only.
- Shortcuts page: "Remove" next to an app shows "Remove Obsidian from the desktop?"; "Remove" moves the card with its 8 shortcuts to the Removed page.
- Removed page: "Bring back app" puts the card back as it was (same place, "1 learned" still there).
- Settings: "Export my list…" opens the Save window with the name filled in; Cancel writes nothing.
- The + on a card opens the editor with the app filled in; the ⌘ button adds the key, "Looks like" shows it at once, and Save adds the shortcut as a 9th row of that app.
- The first change of the day made the dated safety copy and the safety copy, as designed.
Not tried: showing the keys by pointing with the mouse (only the click was tried), typing letters into the Keys field (the test tool could not type there), and the change at midnight.

## Start (changed in 0.6.2)
Refreshes "now" every hour so rechecks appear by themselves.

Why 0.6.2: the system login list (`SMAppService.mainApp`) can fail silently. On 17 Nov 2026 the Mac restarted and did not open AMS Mic Check although its "Open at login" was on (the list could not find it). This app did open that day but relied on the same list alone.

- The keeper (0.6.2): while "Open at login" is on, the app keeps a second, independent start order, the file `~/Library/LaunchAgents/com.schabbauer.AMSShortcutOverview.keeper.plist` (label `com.schabbauer.AMSShortcutOverview.keeper`). It runs the app's own program with `--keeper`; `RunAtLoad`; `KeepAlive` only after an unsuccessful exit; Aqua session; `AssociatedBundleIdentifiers` = the app. It opens the app at every login even if the system list fails, and again after an unexpected stop (measured about 1 s; launchd may wait up to 10 s). A copy the user quit with Quit ends successfully, so it stays closed until opened or the next login. App file: `App/Sources/Keeper.swift`; the plist is built by `Keeper.plist` in `Core` (`ShortcutCore`).
- Check at every start: the app checks that the keeper file is in place and rewrites it if missing. Switching "Open at login" off removes the keeper.
- Hand-over: a copy opened by hand while "Open at login" is on hands itself over (`Keeper.handsOver`): it quits and the keeper starts it about 1 s later, so it is always protected; the cards may blink once. A copy started with `--plain` never hands over (for checks).
- One copy: `OneCopy.mustQuit` (in `Core`) decides between two running copies: it compares start time first, then process number; the earlier one stays, the later one quits. Before 0.6.2 there was no such check (two copies could run, with two key icons and two sets of cards writing the same list).
- Clean stop: on system shutdown or when an update stops the app (SIGTERM) it now ends cleanly, like Quit, so the keeper does not restart it. Before, such a stop cut it off.
- Remembered wish: the setting `wantsOpenAtLogin` is the app's own note that the user wants "Open at login", apart from the system list. The first time it takes what the system list says.
- Test list (the app started with the test folder, used only for checks): neither the keeper nor the one-copy rule is used, so a test copy never becomes the copy the system opens.
- Login Items: System Settings > General > Login Items & Extensions now shows AMS Shortcut Overview twice: under "Open at Login" (the system list) and under "Allow in the Background" (the keeper). Both stay on. The first time the Mac may show "AMS Shortcut Overview added items that can run in the background".
- First start still registers the login item; the switch is in Settings.
- Proven live on 18 Nov 2026 without a restart: a hard stop (the app was back in under 1 second); a second copy opened while one runs (the first stays); the start order forgotten and loaded again, as at login (the app starts with `--keeper`); a polite stop (stays stopped, exit code 0); opened by hand (handed over to the keeper). Not looked at on screen: the new grey line under the switch. Not yet proven: a real restart of the Mac with the keeper (0.6.2).

## Check links
`amsshortcuts://settings | add | day | night | system | snapshot` — snapshot writes `cards-<look>.png` (and the open windows) to `~/Library/Caches/com.schabbauer.AMSShortcutOverview/`.

## Build
`Tools/install.sh` (XcodeGen + xcodebuild, installs to `~/Applications`; since 0.6.2 it stops the running app politely first and afterwards checks that the app runs under the keeper). Rules: `cd Core && swift test` (27 tests; 0.6.2 added two: of two copies the earlier one stays, and the keeper's start order; 0.6.1 had 25, 0.6 had 24, 0.5 had 22, 0.4 had 21 and before 0.4 there were 7: the earlier ones plus tests for weeks in a row, the Removed page, saving, loading and the safety copies, in 0.5 one that checks an exported file reads back exactly as the list was, learned and removed ones included, and in 0.6 two: a file that is not a list is refused, and replacing keeps the list from before as its own copy and the new list reads back exactly, and in 0.6.1 one: the counts tell the list and the Removed page apart). The tests run automatically on GitHub after every change to the code (free, the repository is public). Icon: `Tools/make-icon.py`.
