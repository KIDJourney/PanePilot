#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_ROOT="$(mktemp -d /tmp/panepilot-update-helper.XXXXXX)"
DESTINATION="$TEMP_ROOT/Installed PanePilot.app"
SOURCE_ROOT="$TEMP_ROOT/download"
SOURCE_APP="$SOURCE_ROOT/PanePilot.app"

cleanup() {
  rm -rf "$TEMP_ROOT" "$DESTINATION.panepilot-stage" "$DESTINATION.panepilot-backup"
}
trap cleanup EXIT

mkdir -p "$DESTINATION/Contents" "$SOURCE_APP/Contents"
printf 'old\n' > "$DESTINATION/Contents/version.txt"
printf 'new\n' > "$SOURCE_APP/Contents/version.txt"

PANEPILOT_UPDATE_SKIP_LAUNCH=1 \
  "$ROOT_DIR/Resources/install-update.sh" "$DESTINATION" "$SOURCE_APP" "$SOURCE_ROOT" 999999

[[ "$(cat "$DESTINATION/Contents/version.txt")" == "new" ]]
[[ ! -e "$DESTINATION.panepilot-stage" ]]
[[ ! -e "$DESTINATION.panepilot-backup" ]]
[[ ! -e "$SOURCE_ROOT" ]]

SOURCE_ROOT="$TEMP_ROOT/failed-download"
SOURCE_APP="$SOURCE_ROOT/PanePilot.app"
mkdir -p "$SOURCE_APP/Contents"
printf 'old-again\n' > "$DESTINATION/Contents/version.txt"
printf 'broken-launch\n' > "$SOURCE_APP/Contents/version.txt"

status=0
PANEPILOT_UPDATE_FORCE_LAUNCH_FAILURE=1 \
  "$ROOT_DIR/Resources/install-update.sh" "$DESTINATION" "$SOURCE_APP" "$SOURCE_ROOT" 999999 || status=$?

[[ "$status" == "12" ]]
[[ "$(cat "$DESTINATION/Contents/version.txt")" == "old-again" ]]
[[ ! -e "$DESTINATION.panepilot-stage" ]]
[[ ! -e "$DESTINATION.panepilot-backup" ]]
echo "PanePilot update helper tests passed: replacement completed, and failed launch restored the previous app."
