# rsh

Helper commands for browsing and viewing files on a remote server from the terminal.

## Requirements

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

## License

[MIT](LICENSE)
