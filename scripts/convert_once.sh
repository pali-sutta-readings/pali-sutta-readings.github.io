#!/usr/bin/env bash

ORG_SESSIONS_DIR="$1"
MD_SESSIONS_DIR="$2"

for file in "$ORG_SESSIONS_DIR"/[0-9][0-9][0-9][0-9]-*.org
do
    ./scripts/org_to_md.sh "$file" "$MD_SESSIONS_DIR"
done
