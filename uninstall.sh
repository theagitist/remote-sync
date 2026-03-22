#!/bin/bash
# Uninstall remote-sync: stop agent, remove symlink and plist.

set -e

PLIST_NAME="com.remote-sync"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
BIN_LINK="$HOME/.local/bin/remote-sync.sh"

launchctl unload "$PLIST_DEST" 2>/dev/null && echo "Stopped launchd agent" || true
rm -f "$PLIST_DEST" && echo "Removed $PLIST_DEST"
rm -f "$BIN_LINK" && echo "Removed $BIN_LINK"
echo "Uninstalled."
