#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-SwiftRideFood.xcodeproj}"
SCHEME_NAME="${SCHEME_NAME:-SwiftRideFood}"

if [[ -n "${SIMULATOR_DESTINATION:-}" ]]; then
  echo "$SIMULATOR_DESTINATION"
  exit 0
fi

if [[ -n "${SIMULATOR_ID:-}" ]]; then
  echo "id=${SIMULATOR_ID}"
  exit 0
fi

destinations_output="$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME_NAME" -showdestinations 2>&1 || true)"

candidate_line="$(
  printf "%s\n" "$destinations_output" \
    | awk '/platform:iOS Simulator/ && /id:/ && /OS:/ && /name:iPhone/ { print; exit }'
)"

if [[ -z "$candidate_line" ]]; then
  candidate_line="$(
    printf "%s\n" "$destinations_output" \
      | awk '/platform:iOS Simulator/ && /id:/ && /OS:/ { print; exit }'
  )"
fi

simulator_id="$(
  printf "%s\n" "$candidate_line" \
    | sed -n 's/.*id:\([^,}]*\).*/\1/p'
)"

if [[ -z "$simulator_id" ]]; then
  echo "Unable to resolve an available iOS Simulator destination." >&2
  echo "Hint: Ensure full Xcode is selected (not CommandLineTools) and simulators are installed." >&2
  echo "$destinations_output" >&2
  exit 1
fi

echo "id=${simulator_id}"
