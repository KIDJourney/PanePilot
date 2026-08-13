#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PanePilot"
if [[ -z "${VERSION:-}" ]]; then
  LATEST_TAG="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
  VERSION="${LATEST_TAG#v}"
  VERSION="${VERSION:-0.1.0}"
fi
BUILD="${BUILD:-$(date -u +%Y%m%d%H%M)}"
if [[ -z "${ARTIFACT_LABEL:-}" ]]; then
  CONTENT_HASH="$({
    git -C "$ROOT_DIR" rev-parse HEAD
    git -C "$ROOT_DIR" diff --binary HEAD
    while IFS= read -r path; do
      printf '%s\n' "$path"
      shasum -a 256 "$ROOT_DIR/$path"
    done < <(git -C "$ROOT_DIR" ls-files --others --exclude-standard | sort)
  } | shasum -a 256 | awk '{print substr($1, 1, 12)}')"
  ARTIFACT_LABEL="local-$CONTENT_HASH"
fi

cd "$ROOT_DIR"
VERSION="$VERSION" BUILD="$BUILD" Scripts/build-app.sh

ZIP_PATH="$ROOT_DIR/dist/$APP_NAME-v$VERSION-$ARTIFACT_LABEL-macos-arm64.zip"
rm -f "$ZIP_PATH"
(
  cd "$ROOT_DIR/dist"
  ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

echo "$ZIP_PATH"
