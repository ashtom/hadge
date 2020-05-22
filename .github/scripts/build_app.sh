#!/bin/bash
set -eo pipefail
xcodebuild \
  -project Hadge.xcodeproj/ \
  -scheme Hadge \
  -sdk iphoneos \
  -archivePath $PWD/build/Hadge.xcarchive \
  clean archive
