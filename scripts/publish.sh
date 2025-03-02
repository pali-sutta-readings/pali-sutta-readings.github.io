#!/usr/bin/env bash

set -e

# Source branch

git pull origin source
git add -A .
git status

git commit -m "upd"
git push origin source

make build

# Main branch

cd ../pali-sutta-readings.github.io-main/
git pull origin main
git add -A .
git status

git commit -m "upd"
git push origin main
