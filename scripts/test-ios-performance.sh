#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
destination="$(bash "$script_dir/resolve-ios-simulator-destination.sh")"

echo "Using simulator destination: ${destination}"

mkdir -p build

xcodebuild \
  -project SwiftRideFood.xcodeproj \
  -scheme SwiftRideFood \
  -destination "$destination" \
  -configuration Debug \
  -resultBundlePath build/PerformanceTests.xcresult \
  -only-testing:SwiftRideFoodUITests/SwiftRideFoodPerformanceTests \
  CODE_SIGNING_ALLOWED=NO \
  test
