#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_APP="/Applications/PanePilot Login Item Test.app"
RESULT_PATH="$(mktemp /tmp/panepilot-login-item-result.XXXXXX)"
KEYCHAIN_DIR="$(mktemp -d /tmp/panepilot-login-item-signing.XXXXXX)"
KEYCHAIN_PATH="$KEYCHAIN_DIR/test.keychain-db"
CERT_PATH="${DEVELOPER_ID_APPLICATION_CERT_PATH:-$HOME/Library/Application Support/SpeakMore/signing/developer_id_application.p12}"
CERT_PASSWORD_FILE="${DEVELOPER_ID_APPLICATION_CERT_PASSWORD_FILE:-$HOME/Library/Application Support/SpeakMore/signing/developer_id_application_p12_password.txt}"
ORIGINAL_KEYCHAINS=()

while IFS= read -r keychain; do
  keychain="${keychain#"${keychain%%[![:space:]]*}"}"
  keychain="${keychain#\"}"
  keychain="${keychain%\"}"
  [[ -n "$keychain" ]] && ORIGINAL_KEYCHAINS+=("$keychain")
done < <(security list-keychains -d user)

cleanup() {
  rm -rf "$TEST_APP"
  rm -f "$RESULT_PATH"
  if [[ "${#ORIGINAL_KEYCHAINS[@]}" -gt 0 ]]; then
    security list-keychains -d user -s "${ORIGINAL_KEYCHAINS[@]}" >/dev/null 2>&1 || true
  fi
  security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
  rm -rf "$KEYCHAIN_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
BUNDLE_ID=dev.panepilot.login-item-test Scripts/build-app.sh >/dev/null
rm -rf "$TEST_APP"
ditto dist/PanePilot.app "$TEST_APP"

if [[ ! -f "$CERT_PATH" || ! -f "$CERT_PASSWORD_FILE" ]]; then
  echo "PanePilot login item test failed: Developer ID certificate files are unavailable." >&2
  exit 6
fi

KEYCHAIN_PASSWORD="$(openssl rand -base64 24)"
CERT_PASSWORD="${DEVELOPER_ID_APPLICATION_CERT_PASSWORD:-$(tr -d '\r\n' < "$CERT_PASSWORD_FILE")}"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -k "$KEYCHAIN_PATH" -P "$CERT_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
security list-keychains -d user -s "$KEYCHAIN_PATH" "${ORIGINAL_KEYCHAINS[@]}"

IDENTITY="$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" | awk '/Developer ID Application/{print $2; exit}')"
[[ -n "$IDENTITY" ]]
codesign --force --deep --options runtime --timestamp --keychain "$KEYCHAIN_PATH" --sign "$IDENTITY" "$TEST_APP" >/dev/null

open -W -n "$TEST_APP" --args --automation-login-item-test "$RESULT_PATH"
if [[ ! -s "$RESULT_PATH" ]]; then
  echo "PanePilot login item test failed: LaunchServices produced no result." >&2
  exit 7
fi

code="$(sed -n '1p' "$RESULT_PATH")"
sed -n '2,$p' "$RESULT_PATH"
[[ "$code" = "0" ]]
