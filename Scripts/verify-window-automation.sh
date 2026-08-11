#!/bin/bash

set -euo pipefail

MODE="${1:-}"
case "$MODE" in
  dispatch)
    APP_ARGUMENT="--automation-hotkey-dispatch-test"
    READY_MESSAGE="PanePilot hotkey dispatch ready"
    ;;
  move)
    APP_ARGUMENT="--automation-hotkey-test"
    READY_MESSAGE="PanePilot window move ready"
    ;;
  *)
    echo "usage: $0 dispatch|move" >&2
    exit 64
    ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d /tmp/panepilot-window-automation.XXXXXX)"
OUTPUT_PATH="$TEMP_DIR/panepilot.log"
APP_PID=""

cleanup() {
  if [ -n "$APP_PID" ] && kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

cd "$ROOT_DIR"
pkill -x PanePilot 2>/dev/null || true
swift build -c release --product PanePilot

/usr/bin/perl -e 'alarm shift; exec @ARGV' 10 \
  .build/release/PanePilot "$APP_ARGUMENT" >"$OUTPUT_PATH" 2>&1 &
APP_PID=$!

READY=false
for _ in $(seq 1 50); do
  if /usr/bin/grep -q "$READY_MESSAGE" "$OUTPUT_PATH"; then
    READY=true
    break
  fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [ "$READY" != true ]; then
  wait "$APP_PID" 2>/dev/null || APP_EXIT=$?
  APP_PID=""
  cat "$OUTPUT_PATH"
  exit "${APP_EXIT:-65}"
fi

if [ "$MODE" = dispatch ]; then
  if ! osascript -e 'tell application "System Events" to key code 123 using {option down, command down}'; then
    cat "$OUTPUT_PATH"
    echo "PanePilot automation failed: System Events could not inject Option-Command-Left." >&2
    exit 66
  fi
fi

APP_EXIT=0
wait "$APP_PID" || APP_EXIT=$?
APP_PID=""
cat "$OUTPUT_PATH"
exit "$APP_EXIT"
