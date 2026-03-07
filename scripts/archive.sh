#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_PATH="${ARCHIVE_PATH:-$PWD/build/SwiftRideFood.xcarchive}"

rm -rf "$ARCHIVE_PATH"
mkdir -p "$(dirname "$ARCHIVE_PATH")"

xcodebuild \
  -project SwiftRideFood.xcodeproj \
  -scheme SwiftRideFood \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
  CODE_SIGNING_ALLOWED=NO \
  archive

echo "Archive created at: $ARCHIVE_PATH"
