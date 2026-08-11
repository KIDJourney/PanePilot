#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  Scripts/verify-release.sh v0.1.1

Downloads the GitHub Release DMG and sha256, verifies checksum, stapling, and
Gatekeeper assessment.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

log() {
  printf '\n==> %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

TAG="${1:-}"
if [ -z "$TAG" ] || [ "$TAG" = "-h" ] || [ "$TAG" = "--help" ]; then
  usage
  exit 0
fi
[[ "$TAG" =~ ^v[0-9]+(\.[0-9]+){2}([.-][A-Za-z0-9._-]+)?$ ]] || fail "tag must look like v0.1.1"

require_cmd gh
require_cmd shasum
require_cmd xcrun
require_cmd spctl

TMP_DIR="$(mktemp -d "/tmp/panepilot-verify-$TAG.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log "Download GitHub Release assets"
gh release download "$TAG" \
  --repo KIDJourney/PanePilot \
  --pattern "PanePilot-$TAG.dmg*" \
  --dir "$TMP_DIR" \
  --clobber

DMG="$TMP_DIR/PanePilot-$TAG.dmg"
CHECKSUM="$TMP_DIR/PanePilot-$TAG.dmg.sha256"
[ -f "$DMG" ] || fail "DMG not found in release: $DMG"
[ -f "$CHECKSUM" ] || fail "checksum not found in release: $CHECKSUM"

log "Verify checksum"
(cd "$TMP_DIR" && shasum -a 256 -c "$(basename "$CHECKSUM")")

log "Verify notarization and Gatekeeper"
xcrun stapler validate "$DMG"
spctl -a -vv --type open --context context:primary-signature "$DMG"

log "Release verified"
cat "$CHECKSUM"
