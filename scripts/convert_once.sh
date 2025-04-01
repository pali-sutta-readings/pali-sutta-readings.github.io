#!/usr/bin/env bash

ORG_SESSIONS_DIR="$1"
MD_SESSIONS_DIR="$2"
MD_PRINT_DIR="$3"

# Clean (the now stale) *.md
rm "$MD_SESSIONS_DIR"/*.md
rm "$MD_PRINT_DIR"/*.md

for file in "$ORG_SESSIONS_DIR"/[0-9][0-9][0-9][0-9]-*.org
do
    ./scripts/org_to_md.py "$file" "$MD_SESSIONS_DIR" "$MD_PRINT_DIR"
done
