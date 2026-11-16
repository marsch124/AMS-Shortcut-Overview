# "Learn this app" introduction - concept (AMS Shortcut Overview 0.3)

Facts come from Guide.swift, DesktopCards.swift, ManageView.swift, EditorView.swift, AppDelegate.swift, Starter.json, SPEC.md. Nothing in the app is edited.

---

## Part 1 - The reusable format (any small app)

**One page, one app look.** A single web page that copies the app's real colours, fonts, card shapes and window frames. The page is only a pretend screen; nothing real is touched.

**Layout.** Top: thin progress bar + "Chapter 2 of 6". Middle: the pretend screen (a desktop strip, a menu, or a window). Bottom: one short text (max 2 lines) and one button area. One idea per step.

**Lesson pattern: see - try - check.**
1. SEE: a pretend screen with one thing glowing (a soft ring + a small arrow). Text says what it is, in one or two short sentences. Button: "Next".
2. TRY: the same screen becomes live. Text says one action ("Click the circle."). Only the right spot reacts; other spots give a quiet nudge ("Try the glowing one."). After 8 seconds without action, a "Show me" link animates the pointer.
3. CHECK: one question, 3 big answers, one right. Wrong answer: it greys out with "Not quite - try another"; the right one is shown after the second miss. No score, no penalty.

**Step types.** (a) Look: highlight only. (b) Do: click, hover, right-click, press a key, open a menu, in a mini simulation. (c) Check: 1 question, 3 answers. (d) Real-life: a tick-list of real actions on the real device (chapter at the end).

**Progress.** Bar fills per step; chapters are dots at the top, clickable once reached. Position is remembered on the device, so "Continue" brings him back where he left. "Back" is always there. Every chapter can be repeated, and any step can be skipped ("Skip").

**Success.** Every Do step ends with a small green tick, a one-line message ("Nice - it is crossed out and gone."), and the Next button wakes up in full colour. Never a red error.

**How a lesson ends.** Chapter end: a 1-line recap ("You can now: ...") and "Next chapter". Last chapter: a "Try it for real" checklist (3-4 items, tick boxes he can tick himself on the page), then a finish card: "You know the app." with two buttons: "Start over" and "Open how it works".

**What makes it pleasant.** Short sentences, 2 lines max. Real names and real keys from the app, nothing invented. Day and night follow the system. Big click targets. A little motion (ring pulse, tick draw) but never sound. 5 to 7 chapters, about 5 minutes in all. No sign-in, no data leaves the page. Same HTML skeleton for every app: only a `lesson.json` (chapters, steps, texts, simulated screens) and the app's colour tokens change.

**Lesson file shape (per step):** `text`, `screen` (which pretend view + highlight id), `action` (click / hover / rightclick / key / menu / none), `success` (message), optional `check` (question, 3 answers, right index).

---

## Part 2 - Lesson script for AMS Shortcut Overview

Pretend screens used: DESK (wallpaper with a card strip along the bottom, windows sitting in front), MENU (menu bar with the keycap icon, dropdown), WINDOW (560x520 window with 5 tabs), EDITOR (small "New shortcut" window). Card name = app name + colour from Starter.json.

### Chapter 1 - Meet the cards  (3 steps)
1. SEE. Text: "These colour cards live on your desktop. One card per app." Screen: DESK with 5 cards: Obsidian (purple), Raycast (coral), Fusion (teal), Finder (blue), Xcode (amber). Highlight: whole strip. Action: Next.
2. TRY. Text: "Windows cover the cards. Click the wallpaper to show them." Screen: DESK with two app windows over the cards, cards peeking out beneath. Action: click on empty wallpaper; windows slide away. Success: "Done. On the real Mac you click the wallpaper, or spread thumb and three fingers." (Guide: cards sit at desktop level, windows always cover them.)
3. CHECK. Q: "Where do the cards live?" A: "In the Dock" / "On the desktop, behind your windows" (right) / "In a window you open". Success: "Right. They are always there when you look at the desktop."

### Chapter 2 - Reading a row  (4 steps)
1. SEE. Text: "Each row: circle, what it does, the keys." Screen: Obsidian card, row "Quick switcher" with keys ⌘ O. Highlight in turn: circle, name, keys. Action: Next.
2. TRY (hover). Text: "Point at the keys to learn the symbols." Screen: Obsidian row "Search all files" with keys ⌘ ⇧ F; hovering each key cap shows a label: ⌘ Command, ⇧ Shift. Also shown, not hover-required: ⌥ Option, ⌃ Control (row "Go back" ⌘ ⌥ ←; Safari "Next tab" ⌃ ⇥ is not on the starter desk, so use Obsidian "Go back"). Action: hover all three different keys on the two rows (counter 3/3). Note: hover labels are page-only; the real app has no such labels. Success: "⌘ Command, ⌥ Option, ⌃ Control, ⇧ Shift."
3. SEE. Text: "A card shows 6 rows. More say '+2 more'. The top right shows how many you learned." Screen: Obsidian card with 6 rows, "+2 more" at the bottom, header "N learned" shown after step in chapter 3 (before that, none). Action: Next.
4. CHECK. Q: "What does ⌘ ⇧ F mean in Obsidian?" A: "Search all files" (right) / "New note" / "Insert link". Success: "Yes: Command + Shift + F."

### Chapter 3 - Ticking off  (4 steps)
1. TRY (click). Text: "Know a shortcut? Click its circle." Screen: Finder card, row "Duplicate" ⌘ D. Action: click the circle. Animation: check drawn, name struck through, 0.6 s later the row leaves and the next row ("Move to Bin") moves up. Success: "Gone from the card. Moved to the Learned page."
2. TRY (right-click). Text: "Right-click a row for 'I know it' too." Screen: Finder row "Get info" ⌘ I with context menu: Change…, I know it. Action: right-click, choose "I know it". Success: "Same result."
3. SEE. Text: "After 2 weeks it comes back once, with a 'Recheck' label." Screen: Finder card, pretend date jumped 14 days; "Duplicate" at the top with a "Recheck" capsule. Action: Next.
4. TRY. Text: "Still know it? Click the circle - gone for good. Forgot? Right-click, 'Still learning'." Screen: that row. Action: choose either; both are accepted. Success (tick): "Learned for good." Success (Still learning): "It stays on the card."
   Then CHECK. Q: "When does a learned shortcut come back?" A: "Never" / "After 2 weeks, once" (right) / "Every day". Also noted: when every shortcut of an app is learned, its card disappears (shown as a one-line text, no extra step).

### Chapter 4 - Quiz me and Today's shortcuts  (4 steps)
1. TRY (menu). Text: "Open the key icon in the menu bar. Switch on 'Quiz me'." Screen: MENU with items Add shortcut… (⌘N), Shortcuts and settings… (⌘,), then Show cards on the desktop (tick), Today's shortcuts, Quiz me, then Learned this week: 0 (grey), Version, Quit. Action: click the keycap icon, click "Quiz me". Success: "A tick shows. The keys on the cards turn into '?'."
2. TRY (hover). Text: "Say the keys first. Then point at the row." Screen: Raycast card, all keys as blank caps with "?". Row "Quick Look" shows 2 caps (⌘ Y). Action: hover the row; real keys ⌘ Y appear; move away: hidden again. Success: "Point = look. Move away = hidden."
3. TRY (click). Text: "Click the '?' keys to keep them shown. Click again to hide." Screen: row "Send to AI Chat" ⌘ J. Action: click the keys, then click again. Success: "Handy to look in peace."
4. SEE + CHECK. Text: "'Today's shortcuts' shows a fresh pick on each card every day, new after midnight. The card says 'Today'. Both switches are off until you switch them on." Screen: Fusion card with the "Today" label next to the name. Q: "What does 'Today's shortcuts' change?" A: "Which shortcuts a card shows each day" (right) / "The colours" / "The keys". Success: "Right. Rechecks still come first."

### Chapter 5 - Adding a shortcut  (4 steps)
1. TRY. Text: "Click the + on a card to add a shortcut for that app." Screen: Xcode card, small + at the top right. Action: click +. EDITOR opens titled "New shortcut", app field already "Xcode". (Other two ways, text only: menu "Add shortcut…", or "Add shortcut" in the window.)
2. TRY (fields). Text: "Type what it does. Then the keys." Screen: EDITOR fields App (with a "Pick" menu), What it does (hint "Search all files"), Keys (hint "⌘ ⇧ F") with four buttons ⌘ ⌥ ⌃ ⇧ under it, and a "Looks like" preview. Action: type "Show debug area" in What it does; press the ⌘ and ⇧ buttons, type "Y" in Keys; preview shows ⌘ ⇧ Y. Success: "'Looks like' shows how it will look on the card."
3. TRY (Save / Cancel / Esc). Text: "Save adds it. Cancel or Esc closes without saving." Screen: EDITOR with Cancel and Save (Save is full colour). Action: Save: new row appears on the Xcode card. Second run (optional "Try Esc"): press Esc: the editor closes, nothing added. Success: "Saved." / "Nothing changed."
4. CHECK. Q: "You type a new app name in the App field. What happens?" A: "An error" / "A new card with the next free colour" (right) / "Nothing". Success: "Yes: a new card."

### Chapter 6 - Menu bar menu and window  (5 steps)
1. SEE. Text: "The keycap icon in the menu bar is the app. There is no Dock icon." Screen: MENU bar with the icon highlighted. Action: Next.
2. TRY. Text: "Open it. Find 'Learned this week'." Screen: MENU dropdown as in chapter 4; highlight on the grey line "Learned this week: 3" just above "Version 0.3 (3)". Action: click icon, then click the grey line (nothing happens). Success: "It only shows your count. It cannot be clicked. The week starts on Monday."
3. TRY. Text: "Choose 'Shortcuts and settings…'. The window has 5 pages." Screen: WINDOW with tabs: Shortcuts, Learned, Settings, How it works, What's new. Action: click through each tab once (5/5). Highlights: Learned shows "This week: 3 learned · 12 learned in all". Settings shows show/hide cards, Shortcuts per card (3 to 12), Today's shortcuts, Quiz me, Open at login, Show in Finder, version. Success: "How it works and What's new are always here."
4. TRY (ready-made). Text: "Add a ready-made app: bottom of the Shortcuts page." Screen: WINDOW, Shortcuts page, bottom row with "Version 0.3 (3)", "Add ready-made app", "Add shortcut". Action: click "Add ready-made app"; menu lists "Safari (8 shortcuts)"; pick it. A green Safari card with 8 shortcuts (New tab ⌘ T ...) appears on the desk strip. Success: "Safari added with 8 shortcuts. When all 6 are on your list, the button is greyed out."
5. TRY (remove). Text: "To remove an app, press Remove next to its name." Screen: Shortcuts page, heading "Finder" with Move left, Move right, Remove. Action: press Remove: question "Remove Finder and its 8 shortcuts?" with Cancel / Remove and the line "The card and all its shortcuts go, learned ones too." Action asked: press Cancel first (nothing happens, success "Safe: nothing was removed"), then optionally Remove (pretend card leaves). Success: "Removed. You can add it again, fresh." Then CHECK. Q: "Your Finder shortcuts are learned. You press Remove. What happens to them?" A: "They stay" / "They are removed too" (right) / "They move to Learned". Success: "Yes - a safety copy of the list is kept."

### Chapter 7 - Try it for real  (tick-list, 4 items)
Text: "Four things to do on your real Mac. Tick them here as you go."
1. "Show the desktop (click the wallpaper) and find your colour cards."
2. "Tick one shortcut you really know - click its circle."
3. "Click the keycap in the menu bar and switch on 'Quiz me'. Point at a row."
4. "Press the + on a card and add one shortcut of your own. Save."
Finish card: "You know AMS Shortcut Overview." Buttons: "Start over" / "Open how it works" (tells him: Settings window, How it works page).
Optional bonus line (not a required item): "Switch on 'Today's shortcuts' tomorrow morning."

---

## Accuracy notes for the builder
- The real app does NOT show labels when pointing at ⌘ ⌥ ⌃ ⇧ in normal mode; the hover labels in chapter 2 are a page-only teaching aid. Say so on the page ("This page explains; the app itself does not").
- Real tooltips: tick circle "Tick when you know it" (recheck: "Still know it? Tick to hide it for good"); + button "Add a shortcut for <App>"; hidden keys "Point here or click to see the keys".
- Context menu items are exactly: "Change…", "Still learning" (only on rechecks), "I know it".
- Editor title is "New shortcut" (or "Change shortcut"); Delete appears only when changing an existing one. Errors appear in red for empty app, name or keys.
- The pictures in ~/Library/Caches/com.schabbauer.AMSShortcutOverview/ (cards-night.png, cards-day.png, manage-day.png) were not opened; the page should copy the colours from Palette.swift (day: pale fill, dark title, white key caps; night: deep fill, pale title).
- Day numbers (+2 more, 3 learned, 12 in all) are example values in the pretend screen.
