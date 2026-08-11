#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  Scripts/launch-release-app.sh v0.1.1 [path/to/PanePilot-v0.1.1.dmg]

Mounts the final release DMG, copies PanePilot.app to /tmp, checks Gatekeeper,
opens it with LaunchServices, and verifies the process stays alive.
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
DMG="${2:-}"

if [ -z "$TAG" ] || [ "$TAG" = "-h" ] || [ "$TAG" = "--help" ]; then
  usage
  exit 0
fi
[[ "$TAG" =~ ^v[0-9]+(\.[0-9]+){2}([.-][A-Za-z0-9._-]+)?$ ]] || fail "tag must look like v0.1.1"

require_cmd hdiutil
require_cmd open
require_cmd pgrep
require_cmd pkill
require_cmd spctl

VERSION="${TAG#v}"
if [ -z "$DMG" ]; then
  DMG="build/release/$TAG/PanePilot-$TAG.dmg"
fi
[ -f "$DMG" ] || fail "DMG not found: $DMG"

MOUNT_POINT="$(mktemp -d "/tmp/panepilot-mount-$TAG.XXXXXX")"
MOUNT_POINT="$(cd "$MOUNT_POINT" && pwd -P)"
APP_DEST="/tmp/PanePilot-$TAG-launch-test.app"

cleanup() {
  if mount | grep -q "on $MOUNT_POINT "; then
    hdiutil detach "$MOUNT_POINT" -quiet || true
  fi
  rmdir "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT

log "Stop existing PanePilot"
pkill -x PanePilot 2>/dev/null || true
sleep 0.5

log "Mount final DMG"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_POINT" "$DMG" >/dev/null
[ -d "$MOUNT_POINT/PanePilot.app" ] || fail "PanePilot.app missing inside DMG"

log "Copy app to $APP_DEST"
rm -rf "$APP_DEST"
cp -R "$MOUNT_POINT/PanePilot.app" "$APP_DEST"

log "Gatekeeper assess app"
spctl --assess --type execute --verbose=4 "$APP_DEST"

APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DEST/Contents/Info.plist")"
APP_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_DEST/Contents/Info.plist")"
[ "$APP_VERSION" = "$VERSION" ] || fail "version mismatch: expected $VERSION got $APP_VERSION"
echo "version=$APP_VERSION build=$APP_BUILD"

log "Open app"
open -n "$APP_DEST"

log "Wait for process"
for _ in {1..20}; do
  if pgrep -x PanePilot >/dev/null; then
    PID="$(pgrep -x PanePilot | head -1)"
    sleep 2
    pgrep -x PanePilot >/dev/null || fail "PanePilot exited after launch"
    echo "pid=$PID app=$APP_DEST"
    log "Launch verified"
    exit 0
  fi
  sleep 0.5
done

fail "PanePilot did not start within 10 seconds"
