#!/usr/bin/env bash

set -e

# Source branch

git add -A .
git status

git commit -m "upd"
git push origin source
