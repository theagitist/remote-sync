#!/bin/bash
# Helper commands for browsing synced files on the target server.
# Deployed by remote-sync. Run on the remote server.

SYNC_DIR="${REMOTE_SYNC_DIR:-$(dirname "$0")}"
SELF="$(basename "$0")"

list_files() {
    ls -1t "$SYNC_DIR" | grep -v "^$SELF$"
}

case "${1:-}" in
    --last)
        N="${2:-1}"
        list_files | head -n "$N"
        ;;
    --today)
        TODAY=$(date '+%Y-%m-%d')
        find "$SYNC_DIR" -maxdepth 1 -type f -not -name "$SELF" -newermt "$TODAY" -printf '%T@ %f\n' 2>/dev/null \
            | sort -rn | cut -d' ' -f2-
        ;;
    --search)
        if [ -z "${2:-}" ]; then
            echo "Usage: $SELF --search <term>"
            exit 1
        fi
        list_files | grep -i "$2"
        ;;
    --count)
        COUNT=$(list_files | wc -l)
        echo "$COUNT files"
        ;;
    --view)
        if ! command -v viu &>/dev/null; then
            echo "Error: 'viu' is not installed. Install it with: cargo install viu"
            exit 1
        fi
        TARGET="${2:-latest}"
        if [ "$TARGET" = "latest" ]; then
            FILE=$(list_files | head -n 1)
            if [ -z "$FILE" ]; then
                echo "No files found."
                exit 1
            fi
        else
            FILE="$TARGET"
        fi
        FILEPATH="$SYNC_DIR/$FILE"
        if [ ! -f "$FILEPATH" ]; then
            echo "File not found: $FILEPATH"
            exit 1
        fi
        viu "$FILEPATH"
        ;;
    *)
        cat <<USAGE
Usage: $(basename "$0") <command>

Commands:
  --last [N]      Show the N most recent files (default 1)
  --today         Show files modified today
  --search TERM   Find files by name
  --count         Show total number of files
  --view [FILE]   View an image in the terminal (default: latest)

Set REMOTE_SYNC_DIR to override the sync directory (defaults to script location).
USAGE
        exit 1
        ;;
esac
