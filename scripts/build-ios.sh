#!/usr/bin/env bash
set -euo pipefail

xcodebuild \
  -project SwiftRideFood.xcodeproj \
  -scheme SwiftRideFood \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
