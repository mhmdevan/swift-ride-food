#!/usr/bin/env bash
set -euo pipefail

mkdir -p build

xcodebuild \
  -project SwiftRideFood.xcodeproj \
  -scheme SwiftRideFood \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -configuration Debug \
  -resultBundlePath build/PerformanceTests.xcresult \
  -only-testing:SwiftRideFoodUITests/SwiftRideFoodPerformanceTests \
  CODE_SIGNING_ALLOWED=NO \
  test
