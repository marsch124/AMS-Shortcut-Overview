#!/bin/bash
# Builds AMS Shortcut Overview and puts it in ~/Applications, then starts it.
set -e
cd "$(dirname "$0")/.."
xcodegen generate >/dev/null
xcodebuild -scheme "AMS Shortcut Overview" -configuration Release -derivedDataPath build build 2>&1 | grep -E "error:|BUILD"
osascript -e 'tell application id "com.schabbauer.AMSShortcutOverview" to quit' 2>/dev/null || true
sleep 1
ditto "build/Build/Products/Release/AMS Shortcut Overview.app" "$HOME/Applications/AMS Shortcut Overview.app"
open "$HOME/Applications/AMS Shortcut Overview.app"
