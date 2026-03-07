#!/usr/bin/env bash
set -euo pipefail

CLEAN_PACKAGES="${CLEAN_PACKAGES:-0}"
RETRY_CLEAN_ON_FAILURE="${RETRY_CLEAN_ON_FAILURE:-1}"

packages=(
  Core
  Networking
  Data
  DesignSystem
  Analytics
  FeaturesAuth
  FeaturesHome
  FeaturesMap
  FeaturesOrders
  FeaturesCatalogUIKit
  FeatureFlags
  PushNotifications
)

for package in "${packages[@]}"; do
  echo "Running tests for ${package}..."
  (
    cd "Packages/${package}"
    if [[ "$CLEAN_PACKAGES" == "1" ]]; then
      swift package clean
    fi
    if ! swift test; then
      if [[ "$RETRY_CLEAN_ON_FAILURE" == "1" ]]; then
        echo "Retrying ${package} after clean..."
        swift package clean
        swift test
      else
        exit 1
      fi
    fi
  )
done

echo "All package tests passed."
