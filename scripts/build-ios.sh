#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
destination="$(bash "$script_dir/resolve-ios-simulator-destination.sh")"

echo "Using simulator destination: ${destination}"

xcodebuild \
  -project SwiftRideFood.xcodeproj \
  -scheme SwiftRideFood \
  -destination "$destination" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
