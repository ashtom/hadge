#!/bin/bash
set -eo pipefail

INFO_PLIST=Hadge/Info.plist
current_version=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$INFO_PLIST")
next_version="$((current_version + 1))"
plutil -replace CFBundleVersion -string "$next_version" "$INFO_PLIST"

git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git add $INFO_PLIST
git commit -m "Bump bundle version to $next_version"