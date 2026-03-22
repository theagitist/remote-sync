#!/bin/bash
# Watch a local folder and mirror to one or more remote servers via SSH.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CONFIG="$SCRIPT_DIR/.config"
STATEFILE="/tmp/remote-sync.last"
PLIST_NAME="com.remote-sync"
SYNC_TMPDIR=""

RSYNC_EXCLUDE=(--exclude '.DS_Store' --exclude 'Thumbs.db' --exclude 'rsh.sh')
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/remote-sync-%r@%h:%p -o ControlPersist=300"

if [ ! -f "$CONFIG" ]; then
    echo "Missing .config file. Copy .config.example to .config and fill in your values."
    exit 1
fi

PERMS=$(stat -f '%Lp' "$CONFIG")
if [ "$PERMS" != "600" ]; then
    echo "Insecure .config permissions ($PERMS). Run: chmod 600 $CONFIG"
    exit 1
fi

source "$CONFIG"

FSWATCH="$(command -v fswatch)"
NOTIFIER="$(command -v terminal-notifier)"

cleanup() {
    wait 2>/dev/null
    [ -n "$SYNC_TMPDIR" ] && rm -rf "$SYNC_TMPDIR"
    exit 0
}
trap cleanup SIGTERM SIGINT

sync_once() {
    SYNC_TMPDIR=$(mktemp -d)
    REMOTE_COUNT=${#REMOTE_DIRS[@]}

    for i in "${!REMOTE_DIRS[@]}"; do
        (
            OUTPUT=$(rsync -rltz --delete --itemize-changes "${RSYNC_EXCLUDE[@]}" -e "ssh $SSH_OPTS" "$LOCAL_DIR" "${REMOTE_DIRS[$i]}" 2>&1)
            if [ $? -eq 0 ]; then
                echo "$OUTPUT" | grep -c '^[<>]f' > "$SYNC_TMPDIR/$i"
            else
                echo "FAIL" > "$SYNC_TMPDIR/$i"
            fi
        ) &
    done
    wait

    TOTAL_UPLOADED=0
    FAILED=0
    for i in "${!REMOTE_DIRS[@]}"; do
        RESULT=$(cat "$SYNC_TMPDIR/$i")
        if [ "$RESULT" = "FAIL" ]; then
            FAILED=$((FAILED + 1))
        else
            TOTAL_UPLOADED=$((TOTAL_UPLOADED + RESULT))
        fi
    done
    rm -rf "$SYNC_TMPDIR"
    SYNC_TMPDIR=""

    date +%s > "$STATEFILE"

    if [ "$FAILED" -gt 0 ]; then
        [ "$FAILED" -eq 1 ] && MSG="1 remote" || MSG="$FAILED remotes"
        "$NOTIFIER" -title "Remote Sync" -message "Sync failed for $MSG" -sound Basso
    elif [ "$TOTAL_UPLOADED" -gt 0 ]; then
        [ "$REMOTE_COUNT" -eq 1 ] && LABEL="remote" || LABEL="remotes"
        "$NOTIFIER" -title "Remote Sync" -message "$TOTAL_UPLOADED file(s) synced to $REMOTE_COUNT $LABEL" -sound Glass
    fi
}

case "${1:-}" in
    --once)
        sync_once
        ;;
    --status)
        if launchctl list "$PLIST_NAME" &>/dev/null; then
            PID=$(launchctl list "$PLIST_NAME" | awk '/PID/ {print $NF}')
            echo "Agent: running (PID $PID)"
        else
            echo "Agent: not loaded"
        fi
        if [ -f "$STATEFILE" ]; then
            LAST=$(cat "$STATEFILE")
            echo "Last sync: $(date -r "$LAST" '+%Y-%m-%d %H:%M:%S')"
        else
            echo "Last sync: never"
        fi
        echo "Watching: $LOCAL_DIR"
        echo "Remotes: ${REMOTE_DIRS[*]}"
        ;;
    --deploy)
        HELPERS="$SCRIPT_DIR/rsh.sh"
        if [ ! -f "$HELPERS" ]; then
            echo "Missing rsh.sh in $SCRIPT_DIR"
            exit 1
        fi
        for REMOTE_DIR in "${REMOTE_DIRS[@]}"; do
            HOST="${REMOTE_DIR%%:*}"
            PATH_PART="${REMOTE_DIR#*:}"
            scp -q "$HELPERS" "$HOST:$PATH_PART/rsh.sh"
            ssh "$HOST" "chmod +x '$PATH_PART/rsh.sh'"
            echo "Deployed helpers to $HOST:$PATH_PART"
        done
        ;;
    "")
        "$FSWATCH" -o -l 3 "$LOCAL_DIR" | while read -r _; do
            sync_once
        done
        ;;
    *)
        cat <<USAGE
Usage: $(basename "$0") <command>

Commands:
  (none)          Start the file watcher (used by launchd)
  --once          Run a one-off sync
  --status        Show agent status and last sync time
  --deploy        Deploy helper script to all remote servers
USAGE
        exit 1
        ;;
esac
