#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <installed-app-path>" >&2
  exit 1
fi

APP_PATH="$1"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "App not found: ${APP_PATH}" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
spctl -a -vv --type execute "${APP_PATH}"
open -na "${APP_PATH}"
sleep 3

if ! pgrep -x DefaultEditorSwitcher >/dev/null; then
  echo "DefaultEditorSwitcher did not appear to launch." >&2
  exit 1
fi

cat <<'EOF'
Installed app verification passed.

Next manual checks:
1. Open the menu bar app from the installed build.
2. Confirm one successful global editor switch.
3. Confirm one failure scenario shows the recovery block and "Open Settings for Recovery".
EOF
