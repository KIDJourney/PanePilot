#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PanePilot"
VERSION="${VERSION:-0.1.0}"

cd "$ROOT_DIR"
Scripts/build-app.sh

ZIP_PATH="$ROOT_DIR/dist/$APP_NAME-v$VERSION-macos-arm64.zip"
rm -f "$ZIP_PATH"
(
  cd "$ROOT_DIR/dist"
  ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

echo "$ZIP_PATH"
