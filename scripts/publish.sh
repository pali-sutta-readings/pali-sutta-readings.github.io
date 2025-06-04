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

# Avoid merge commits, stash changes if there are any.
stashed=false
# Add untracked files.
git add -A .
if ! git diff --cached --quiet; then
  if ! git stash push -q; then
    echo "Failed to stash changes"
    exit 1
  fi
  stashed=true
fi

if ! git pull --rebase origin "$SOURCE_BRANCH"; then
  echo "Pull failed, restoring stashed changes"
  if $stashed; then
    git stash pop || echo "Warning: Could not restore stashed changes"
  fi
  exit 1
fi

# Restore stashed changes
if $stashed; then
  if ! git stash pop; then
    echo "Warning: Failed to restore stashed changes"
  fi
fi

# Detect source changes and commit all updates.
if ! git diff --cached --quiet; then
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
