#!/bin/zsh
set -euo pipefail

destination="$1"
source_app="$2"
temporary_root="$3"
app_pid="$4"
stage="${destination}.panepilot-stage"
backup="${destination}.panepilot-backup"

for _ in {1..100}; do
  kill -0 "$app_pid" 2>/dev/null || break
  sleep 0.1
done
kill -0 "$app_pid" 2>/dev/null && exit 10

rm -rf "$stage" "$backup"
/usr/bin/ditto "$source_app" "$stage"
/bin/mv "$destination" "$backup"
if /bin/mv "$stage" "$destination"; then
  if [[ "${PANEPILOT_UPDATE_SKIP_LAUNCH:-0}" == "1" ]] || \
    { [[ "${PANEPILOT_UPDATE_FORCE_LAUNCH_FAILURE:-0}" != "1" ]] && /usr/bin/open -n "$destination" >/dev/null 2>&1; }; then
    /bin/rm -rf "$backup" "$temporary_root"
  else
    /bin/rm -rf "$destination"
    /bin/mv "$backup" "$destination"
    /usr/bin/open -n "$destination" >/dev/null 2>&1 || true
    exit 12
  fi
else
  /bin/mv "$backup" "$destination" || true
  exit 11
fi
