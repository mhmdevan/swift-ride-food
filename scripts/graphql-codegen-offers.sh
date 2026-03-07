#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/Packages/FeaturesCatalogUIKit"
CONFIG_PATH="${PACKAGE_DIR}/GraphQL/apollo-codegen-config.json"

if ! command -v apollo-ios-cli >/dev/null 2>&1; then
  echo "apollo-ios-cli is not installed."
  echo "Install: brew install apollo-ios-cli"
  exit 1
fi

apollo-ios-cli generate --path "${CONFIG_PATH}"

echo "Apollo GraphQL codegen completed using: ${CONFIG_PATH}"
