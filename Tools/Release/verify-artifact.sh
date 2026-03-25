#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <exported-app-path> <zip-path>" >&2
  exit 1
fi

APP_PATH="$1"
ZIP_PATH="$2"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST_PATH="${ROOT_DIR}/build/release/release-manifest.txt"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "App not found: ${APP_PATH}" >&2
  exit 1
fi

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Zip not found: ${ZIP_PATH}" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
spctl -a -vv --type execute "${APP_PATH}"
xcrun stapler validate "${APP_PATH}"

if [[ -f "${MANIFEST_PATH}" ]]; then
  submission_id="$(awk -F= '/^submission_id=/{print $2}' "${MANIFEST_PATH}")"
  if [[ -n "${submission_id}" ]]; then
    xcrun notarytool log "${submission_id}"
  fi
fi

echo "Artifact verification passed:"
echo "  App: ${APP_PATH}"
echo "  Zip: ${ZIP_PATH}"
