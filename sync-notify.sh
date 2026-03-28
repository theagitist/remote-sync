#!/bin/bash
# Notify when Syncthing finishes syncing a folder to a remote device.
# Polls the Syncthing Events API and fires a macOS notification on completion.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/.sync-notify.conf"

if [ ! -f "$CONFIG" ]; then
    echo "Missing config. Copy .sync-notify.conf.example to .sync-notify.conf and fill in your values."
    exit 1
fi

source "$CONFIG"

: "${ST_API_KEY:?Set ST_API_KEY in $CONFIG}"
: "${ST_FOLDER_ID:?Set ST_FOLDER_ID in $CONFIG}"
: "${ST_URL:=http://localhost:8384}"
: "${ST_NOTIFY_TITLE:=Syncthing}"
: "${ST_NOTIFY_MESSAGE:=Screenshot synced to remote}"
: "${ST_NOTIFY_SOUND:=Glass}"

PLIST_NAME="com.sync-notify"
LAST_ID=0

NOTIFIER="$(command -v terminal-notifier)"
if [ -z "$NOTIFIER" ]; then
    echo "Missing terminal-notifier. Install with: brew install terminal-notifier"
    exit 1
fi

notify() {
    "$NOTIFIER" -title "$ST_NOTIFY_TITLE" -message "$1" -sound "$ST_NOTIFY_SOUND"
}

poll() {
    curl -sf -H "X-API-Key: $ST_API_KEY" \
        "$ST_URL/rest/events?events=FolderCompletion&since=$LAST_ID&timeout=60" 2>/dev/null || echo "[]"
}

case "${1:-}" in
    --install)
        BIN_LINK="$HOME/.local/bin/sync-notify.sh"
        PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

        mkdir -p "$(dirname "$BIN_LINK")"
        ln -sf "$SCRIPT_DIR/sync-notify.sh" "$BIN_LINK"
        chmod +x "$SCRIPT_DIR/sync-notify.sh"

        launchctl unload "$PLIST_DEST" 2>/dev/null || true

        cat > "$PLIST_DEST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_LINK</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/sync-notify.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/sync-notify.log</string>
</dict>
</plist>
EOF

        launchctl load "$PLIST_DEST"
        echo "Installed and started launchd agent: $PLIST_NAME"
        ;;
    --uninstall)
        PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
        BIN_LINK="$HOME/.local/bin/sync-notify.sh"
        launchctl unload "$PLIST_DEST" 2>/dev/null && echo "Stopped agent" || true
        rm -f "$PLIST_DEST" && echo "Removed $PLIST_DEST"
        rm -f "$BIN_LINK" && echo "Removed $BIN_LINK"
        echo "Uninstalled."
        ;;
    --status)
        if launchctl list "$PLIST_NAME" &>/dev/null; then
            PID=$(launchctl list "$PLIST_NAME" | awk '/PID/ {print $NF}')
            echo "Agent: running (PID $PID)"
        else
            echo "Agent: not loaded"
        fi
        echo "Watching folder: $ST_FOLDER_ID"
        echo "Syncthing URL: $ST_URL"
        ;;
    "")
        echo "Listening for sync completions on folder '$ST_FOLDER_ID'..."
        while true; do
            EVENTS=$(poll)

            if [ "$EVENTS" = "[]" ] || [ -z "$EVENTS" ]; then
                continue
            fi

            # Parse events line by line to avoid subshell variable scoping
            while IFS= read -r line; do
                EVENT_ID=$(echo "$line" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
                FOLDER=$(echo "$line" | sed -n 's/.*"folder":"\([^"]*\)".*/\1/p')
                COMPLETION=$(echo "$line" | sed -n 's/.*"completion":\([0-9.]*\).*/\1/p')

                [ -n "$EVENT_ID" ] && [ "$EVENT_ID" -gt "$LAST_ID" ] && LAST_ID=$EVENT_ID

                if [ "$FOLDER" = "$ST_FOLDER_ID" ] && [ "${COMPLETION%.*}" = "100" ]; then
                    notify "$ST_NOTIFY_MESSAGE"
                fi
            done <<< "$(echo "$EVENTS" | tr '}' '\n')"
        done
        ;;
    *)
        cat <<USAGE
Usage: $(basename "$0") [command]

Commands:
  (none)        Start listening for sync events (foreground)
  --install     Install as a launchd agent
  --uninstall   Remove the launchd agent
  --status      Show agent status
USAGE
        exit 1
        ;;
esac
