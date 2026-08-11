#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  Scripts/release-local.sh v0.1.1

Environment:
  CODESIGN_IDENTITY             Optional. Developer ID Application identity SHA or name.
  NOTARY_PROFILE                Optional. notarytool keychain profile name.
  APPLE_ID                      Required when NOTARY_PROFILE is not set.
  APPLE_APP_SPECIFIC_PASSWORD   Required when NOTARY_PROFILE is not set.
  APPLE_TEAM_ID                 Required when NOTARY_PROFILE is not set.
  RELEASE_NOTES                 Optional. GitHub release notes.
  BUILD                         Optional. CFBundleVersion. Defaults to UTC timestamp.

Builds, Developer ID signs, notarizes, staples, validates, creates/pushes the
tag, and uploads a DMG plus sha256 to GitHub Releases.
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

notary_submit() {
  local path="$1"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$path" --keychain-profile "$NOTARY_PROFILE" --wait
    return
  fi

  [ -n "${APPLE_ID:-}" ] || fail "APPLE_ID is required when NOTARY_PROFILE is not set"
  [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ] || fail "APPLE_APP_SPECIFIC_PASSWORD is required when NOTARY_PROFILE is not set"
  [ -n "${APPLE_TEAM_ID:-}" ] || fail "APPLE_TEAM_ID is required when NOTARY_PROFILE is not set"

  xcrun notarytool submit "$path" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TAG="${1:-}"
if [ -z "$TAG" ] || [ "$TAG" = "-h" ] || [ "$TAG" = "--help" ]; then
  usage
  exit 0
fi
[[ "$TAG" =~ ^v[0-9]+(\.[0-9]+){2}([.-][A-Za-z0-9._-]+)?$ ]] || fail "tag must look like v0.1.1"
VERSION="${TAG#v}"
BUILD="${BUILD:-$(date -u +%Y%m%d%H%M)}"

require_cmd swift
require_cmd codesign
require_cmd xcrun
require_cmd ditto
require_cmd dmgbuild
require_cmd gh
require_cmd git
require_cmd python3
require_cmd shasum
require_cmd spctl

[ -z "$(git status --porcelain)" ] || fail "working tree must be clean before releasing"

if [ -z "${RELEASE_NOTES:-}" ]; then
  BASE_REF="$(git describe --tags --abbrev=0 --match 'v*' HEAD^ 2>/dev/null || true)"
  RANGE="HEAD"
  if [ -n "$BASE_REF" ]; then
    RANGE="$BASE_REF..HEAD"
  fi
  RELEASE_NOTES="$(git log --no-merges --format='- %s' "$RANGE" | head -n 8)"
  if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="- Developer ID signed and notarized release"
  fi
fi

IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ]; then
  IDENTITY="$(security find-identity -v -p codesigning | awk '/Developer ID Application/{print $2; exit}')"
fi
[ -n "$IDENTITY" ] || fail "no Developer ID Application identity found"

BUILD_DIR="$ROOT_DIR/build/release/$TAG"
DMG_PATH="$BUILD_DIR/PanePilot-$TAG.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
SETTINGS_PATH="$BUILD_DIR/dmgbuild-settings.py"
NOTARY_ZIP="$BUILD_DIR/PanePilot-notary.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log "Build app bundle"
VERSION="$VERSION" BUILD="$BUILD" Scripts/build-app.sh
APP_PATH="$ROOT_DIR/dist/PanePilot.app"
[ -d "$APP_PATH" ] || fail "app bundle not found: $APP_PATH"

BUILT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
[ "$BUILT_VERSION" = "$VERSION" ] || fail "tag $TAG does not match built version $BUILT_VERSION"

log "Sign app with Developer ID"
codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

log "Notarize and staple app"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"
notary_submit "$NOTARY_ZIP"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl -a -vv --type execute "$APP_PATH"

log "Package DMG"
APP_PATH_PY="$(python3 -c 'import sys; print(repr(sys.argv[1]))' "$APP_PATH")"
cat > "$SETTINGS_PATH" <<PY
format = "UDZO"
filesystem = "HFS+"
compression_level = 9
window_rect = ((200, 120), (560, 340))
default_view = "icon-view"
show_status_bar = False
show_toolbar = False
show_sidebar = False
icon_size = 96
text_size = 13
arrange_by = None
files = [($APP_PATH_PY, "PanePilot.app")]
symlinks = {"Applications": "/Applications"}
icon_locations = {
    "PanePilot.app": (170, 165),
    "Applications": (390, 165),
}
PY
dmgbuild -s "$SETTINGS_PATH" "PanePilot" "$DMG_PATH"

log "Sign, notarize, and staple DMG"
codesign --force --timestamp --sign "$IDENTITY" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
notary_submit "$DMG_PATH"
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vv --type open --context context:primary-signature "$DMG_PATH"

log "Checksum"
(cd "$BUILD_DIR" && shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$CHECKSUM_PATH")")
(cd "$BUILD_DIR" && shasum -a 256 -c "$(basename "$CHECKSUM_PATH")")

log "Create and push tag"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  TAG_SHA="$(git rev-list -n 1 "$TAG")"
  HEAD_SHA="$(git rev-parse HEAD)"
  [ "$TAG_SHA" = "$HEAD_SHA" ] || fail "$TAG points to $TAG_SHA, not current HEAD $HEAD_SHA"
else
  git tag "$TAG"
fi
git push origin "$TAG"

log "Upload GitHub Release"
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "$DMG_PATH" "$CHECKSUM_PATH" --clobber
  gh release edit "$TAG" --notes "$RELEASE_NOTES"
else
  gh release create "$TAG" \
    "$DMG_PATH" \
    "$CHECKSUM_PATH" \
    --target "$(git rev-parse HEAD)" \
    --title "PanePilot $TAG" \
    --notes "$RELEASE_NOTES"
fi

log "Done"
echo "$DMG_PATH"
