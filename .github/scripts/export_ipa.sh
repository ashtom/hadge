#!/bin/bash
set -eo pipefail
xcodebuild \
  -archivePath $PWD/build/Hadge.xcarchive \
  -exportOptionsPlist Hadge/ExportOptions.plist \
  -exportPath $PWD/build \
  -allowProvisioningUpdates \
  -exportArchive