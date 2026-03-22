#!/bin/bash
# Install remote-sync: symlink script + launchd agent, generate plist.

set -e

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$REPO_DIR/remote-sync.sh"
PLIST_NAME="com.remote-sync"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
BIN_LINK="$HOME/.local/bin/remote-sync.sh"

# Check config exists
if [ ! -f "$REPO_DIR/.config" ]; then
    echo "Create a .config file first:"
    echo "  cp .config.example .config"
    echo "  # then edit .config with your values"
    exit 1
fi

# Secure config permissions
chmod 600 "$REPO_DIR/.config"

# Validate LOCAL_DIR
source "$REPO_DIR/.config"
if [ ! -d "$LOCAL_DIR" ]; then
    echo "LOCAL_DIR does not exist: $LOCAL_DIR"
    echo "Check your .config file."
    exit 1
fi

# Check dependencies
for cmd in fswatch terminal-notifier rsync; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing: $cmd"
        echo "Install with: brew install fswatch terminal-notifier"
        exit 1
    fi
done

# Symlink script
mkdir -p "$(dirname "$BIN_LINK")"
ln -sf "$SCRIPT_PATH" "$BIN_LINK"
chmod +x "$SCRIPT_PATH"
echo "Symlinked $BIN_LINK -> $SCRIPT_PATH"

# Unload existing agent if loaded
launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Generate plist pointing to the symlink
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
</dict>
</plist>
EOF

# Load agent
launchctl load "$PLIST_DEST"
echo "Loaded launchd agent: $PLIST_NAME"

# Deploy helpers to remotes
"$BIN_LINK" --deploy

echo "Remote sync is now running."
