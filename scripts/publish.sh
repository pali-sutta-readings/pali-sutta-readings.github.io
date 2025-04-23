#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

SOURCE_DIR=$(pwd)
SOURCE_BRANCH="source"
TARGET_DIR="../pali-sutta-readings.github.io-main"
TARGET_BRANCH="main"

# --- Update source branch and commit changes ---

if [[ $(git branch --show-current) != "$SOURCE_BRANCH" ]]; then
    echo "Error: Must be on the '$SOURCE_BRANCH' branch."
    exit 1
fi

# Avoid merge commits.
git stash
git pull --rebase origin "$SOURCE_BRANCH"
git stash pop

# Detect source changes and commit all updates.
if ! git diff --quiet HEAD; then
  git add -A .
  git status
  git commit -m "upd"
  git push origin "$SOURCE_BRANCH"
fi

# --- Commit and push target branch ---

# Reset TARGET_DIR to remote state FIRST
cd "$TARGET_DIR"
git checkout "$TARGET_BRANCH"

git fetch origin "$TARGET_BRANCH"
git reset --hard origin/"$TARGET_BRANCH"

# Back to source, now generate fresh HTML files to TARGET_DIR
cd "$SOURCE_DIR"
poetry run mkdocs build -d "$TARGET_DIR"

cd "$TARGET_DIR"
touch .nojekyll

if [[ $(git status -s) != "" ]]; then
    git add -A .
    git status
    git commit -m "upd"
    git push origin "$TARGET_BRANCH"
fi
