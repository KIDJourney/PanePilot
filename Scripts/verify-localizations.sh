#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/dist/PanePilot.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/PanePilot"

cd "$ROOT_DIR"
if [ ! -x "$EXECUTABLE" ]; then
  make app
fi

for language in en zh-Hans; do
  STRINGS_PATH="$APP_PATH/Contents/Resources/$language.lproj/Localizable.strings"
  test -f "$STRINGS_PATH"
  plutil -lint "$STRINGS_PATH" >/dev/null
done

ENGLISH_KEYS="$(plutil -p "$APP_PATH/Contents/Resources/en.lproj/Localizable.strings" | sed -n 's/^  "\(.*\)" =>.*/\1/p' | sort)"
CHINESE_KEYS="$(plutil -p "$APP_PATH/Contents/Resources/zh-Hans.lproj/Localizable.strings" | sed -n 's/^  "\(.*\)" =>.*/\1/p' | sort)"
test "$ENGLISH_KEYS" = "$CHINESE_KEYS"

ENGLISH="$(PANEPILOT_TEST_LANGUAGE=en "$EXECUTABLE" --automation-localization-test)"
CHINESE="$(PANEPILOT_TEST_LANGUAGE=zh-Hans "$EXECUTABLE" --automation-localization-test)"

test "$ENGLISH" = "PanePilot Settings|Center|Check for Updates...|Open PanePilot automatically when you log in.|Install Update|PanePilot Could Not Update|Recording Right Half. Press Escape to cancel.|3 of 18 shortcuts active"
test "$CHINESE" = "PanePilot 设置|居中|检查更新...|登录后自动打开 PanePilot。|安装更新|PanePilot 无法更新|正在录制右半屏。按 Escape 取消。|已启用 3/18 个快捷键"

echo "PanePilot localization verification passed: en and zh-Hans resources are bundled and selectable."
