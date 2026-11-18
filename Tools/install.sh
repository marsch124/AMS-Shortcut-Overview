#!/bin/bash
# Builds AMS Shortcut Overview and puts it in ~/Applications, then starts it.
set -e
cd "$(dirname "$0")/.."
xcodegen generate >/dev/null
xcodebuild -scheme "AMS Shortcut Overview" -configuration Release -derivedDataPath build build 2>&1 | grep -E "error:|BUILD"
osascript -e 'tell application id "com.schabbauer.AMSShortcutOverview" to quit' 2>/dev/null || true
sleep 1
# A polite stop for what is left: the app ends cleanly, so the keeper does not reopen it.
pkill -TERM -x "AMS Shortcut Overview" 2>/dev/null && sleep 1 || true
ditto "build/Build/Products/Release/AMS Shortcut Overview.app" "$HOME/Applications/AMS Shortcut Overview.app"
open "$HOME/Applications/AMS Shortcut Overview.app"

# Opened by hand, the app hands itself over to the keeper (0.6.2): check that it did.
SERVICE="gui/$(id -u)/com.schabbauer.AMSShortcutOverview.keeper"
for _ in $(seq 1 30); do
    launchctl print "$SERVICE" 2>/dev/null | grep -q "state = running" && break
    sleep 0.2
done
if launchctl print "$SERVICE" 2>/dev/null | grep -q "state = running"; then echo "Running under the keeper"; else echo "warning: NOT running under the keeper"; fi
