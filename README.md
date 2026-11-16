# AMS Shortcut Overview

<img src="Docs/icon-1024.png" width="96" align="right">

A small Mac menu bar app that puts the keyboard shortcuts you are learning on your desktop: one colour card per app, along the bottom of the screen (a second row above when they do not fit), behind your windows. Tick a shortcut when you know it and it is hidden from the card (it stays in your list); two weeks later it comes back once to check you still know it. Nothing is ever deleted: "Remove" only moves a shortcut or an app to a Removed page, and you can bring it back.

- Starts with 8 shortcuts each for Obsidian, Raycast, Autodesk Fusion, Finder and Xcode; Safari, Mail and Notes (8 each) are ready-made too and wait in "Add ready-made app".
- Counts your learned shortcuts per week and the weeks in a row.
- Your list is safe: a safety copy, one dated copy per day for 30 days, and a warning if saving fails.
- Add your own from the menu bar or the + on a card; any app gets its own colour.
- Day and night colours. Nothing leaves your Mac.

Build: `Tools/install.sh` (needs XcodeGen). Rules and tests: `Core` (`swift test`). Details: [Docs/SPEC.md](Docs/SPEC.md).
