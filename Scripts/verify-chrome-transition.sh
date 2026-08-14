#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TEMP_DIR="$(mktemp -d /tmp/panepilot-chrome-transition.XXXXXX)"
CHROME_PID=""

cleanup() {
  if [ -n "$CHROME_PID" ] && kill -0 "$CHROME_PID" 2>/dev/null; then
    kill "$CHROME_PID" 2>/dev/null || true
    wait "$CHROME_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

if [ ! -x "$CHROME_EXECUTABLE" ]; then
  echo "PanePilot Chrome transition skipped: Google Chrome is not installed." >&2
  exit 69
fi

cd "$ROOT_DIR"
swift build -c release --product PanePilot

"$CHROME_EXECUTABLE" \
  --user-data-dir="$TEMP_DIR/profile" \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-component-update \
  --disable-default-apps \
  --new-window about:blank \
  >"$TEMP_DIR/chrome.log" 2>&1 &
CHROME_PID=$!

.build/release/PanePilot --automation-chrome-transition-test "$CHROME_PID"
