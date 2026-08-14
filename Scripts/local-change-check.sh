#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Validate docs locally"
make validate-docs

echo "==> Build locally"
swift build

echo "==> Test locally"
swift test

echo "==> Package local preview artifact"
make package

echo "==> Verify bundled localizations"
make verify-localizations

codesign --verify --deep --strict --verbose=2 dist/PanePilot.app
ARTIFACT="$(find dist -maxdepth 1 -name 'PanePilot-v*-local-*-macos-arm64.zip' -type f -exec stat -f '%m %N' {} + | sort -nr | head -1 | cut -d' ' -f2-)"
test -n "$ARTIFACT"
echo "Local change check passed. Artifact: $ARTIFACT"
