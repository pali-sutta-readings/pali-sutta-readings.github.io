#!/usr/bin/env bash

set -e

# Source branch

if [[ $(git branch --show-current) != "source" ]]; then
    echo "Error: Must be on the 'source' branch."
fi

git pull origin source
git add -A .
git status

git commit -m "upd"
git push origin source

# Main branch

cd ../pali-sutta-readings.github.io-main/

if [[ $(git branch --show-current) != "main" ]]; then
    echo "Error: Must be on the 'main' branch."
fi

git pull origin main
touch .nojekyll
git add -A .
git status

git commit -m "upd"
git push origin main
