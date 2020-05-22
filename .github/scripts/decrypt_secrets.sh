#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$CERTIFICATE_GPG_KEY" --output ./.github/secrets/team.mobileprovision ./.github/secrets/team.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$CERTIFICATE_GPG_KEY" --output ./.github/secrets/development.p12 ./.github/secrets/development.p12.gpg

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp ./.github/secrets/team.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/team.mobileprovision


security create-keychain -p "" build.keychain
security import ./.github/secrets/development.p12 -t agg -k ~/Library/Keychains/build.keychain -P "" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain