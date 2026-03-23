# remote-sync

Automatically sync a local folder to one or more remote servers via SSH. Uses `fswatch` to detect changes and `rsync` to mirror files — including deletions.

Runs on **macOS** as the source machine (uses launchd and macOS notifications). The remote target can be **any OS** that supports SSH and rsync (Linux, BSD, etc.).

## Requirements

**Source (macOS):**
- [Homebrew](https://brew.sh)
- SSH key-based access to your remote server(s)

**Target (any OS):**
- SSH server
- `rsync` installed

## Install

```bash
brew install fswatch terminal-notifier

git clone https://github.com/theagitist/remote-sync.git
cd remote-sync

cp .config.example .config
# Edit .config with your local path and remote destination(s)

./install.sh
```

The install script will:
- Symlink the sync script to `~/.local/bin/`
- Generate and load a launchd agent that keeps it running
- Lock `.config` permissions to owner-only (600)

## Configuration

Edit `.config` with your paths:

```bash
# Absolute path to the local folder to watch
LOCAL_DIR="/path/to/your/folder/"

# One or more remote destinations (SSH + rsync)
REMOTE_DIRS=(
    "user@server1.com:/path/to/folder/"
    "user@server2.com:/path/to/folder/"
)
```

## Usage

The sync runs automatically in the background. You can also use:

```bash
remote-sync.sh --once          # One-off sync without the watcher
remote-sync.sh --status        # Agent status and last sync time
remote-sync.sh --deploy        # Deploy helper scripts to all remotes
```

### Target helpers

Deploy helper scripts to your remote servers:

```bash
remote-sync.sh --deploy
```

Then on the target server, from the sync directory:

```bash
./rsh.sh --last          # Most recent filename
./rsh.sh --last 5        # Last 5 files
./rsh.sh --today         # Files modified today
./rsh.sh --search term   # Find files by name
./rsh.sh --count         # Total number of files
./rsh.sh --view          # View the latest image in the terminal (requires viu)
./rsh.sh --view foo.png  # View a specific image
```

## Uninstall

```bash
./uninstall.sh
```

## License

[MIT](LICENSE)
