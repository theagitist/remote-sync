# rsh

Helper commands for browsing and viewing files on a remote server from the terminal.

## Requirements

- `terminal-notifier` (for sync notifications) — `brew install terminal-notifier`
- `viu` (optional, for `--view`) — install with `cargo install viu`

## Usage

Place `rsh.sh` in the directory you want to browse, then:

```bash
./rsh.sh --last          # Most recent filename
./rsh.sh --last 5        # Last 5 files
./rsh.sh --today         # Files modified today
./rsh.sh --search term   # Find files by name
./rsh.sh --count         # Total number of files
./rsh.sh --view          # View the latest image in the terminal (requires viu)
./rsh.sh --view foo.png  # View a specific image
```

Set `REMOTE_SYNC_DIR` to override the target directory (defaults to the script's location).

## Sync notifications

`sync-notify.sh` watches Syncthing's Events API and fires a macOS notification when a folder finishes syncing to a remote device.

### Setup

```bash
cp .sync-notify.conf.example .sync-notify.conf
# Edit .sync-notify.conf with your Syncthing API key and folder ID
```

Find your API key in the Syncthing GUI under **Actions > Settings > API Key**. The folder ID is shown under each folder's name in the GUI.

### Run

```bash
./sync-notify.sh              # Run in foreground
./sync-notify.sh --install    # Install as a background launchd agent
./sync-notify.sh --uninstall  # Remove the agent
./sync-notify.sh --status     # Check if the agent is running
```

### Focus mode

Notifications are delivered via `terminal-notifier`. To receive them while a Focus mode is active:

1. Open **System Settings > Focus**
2. Select your active Focus profile
3. Under **Allowed Notifications**, click **Apps**
4. Add **terminal-notifier** to the list

## License

[MIT](LICENSE)
