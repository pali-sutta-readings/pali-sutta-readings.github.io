#!/usr/bin/env bash

# Requires:
# sudo apt-get install inotify-tools
# sudo pacman -S inotify-tools
#
# See also:
# man inotifywait
# https://askubuntu.com/questions/819265/command-to-monitor-file-changes-within-a-directory-and-execute-command

ORG_SESSIONS_DIR="$1"
MD_SESSIONS_DIR="$2"

# Create an initial version before changes.
./scripts/convert_once.sh "$ORG_SESSIONS_DIR" "$MD_SESSIONS_DIR"

# Start watcher.
inotifywait -m --event modify --format '%w' "$ORG_SESSIONS_DIR"/[0-9][0-9][0-9][0-9]-*.org | while read -r file ; do
    ./scripts/org_to_md.py "$file" "$MD_SESSIONS_DIR"
done
