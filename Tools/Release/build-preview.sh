#!/usr/bin/env bash

set -euo pipefail

require_command() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Missing required command: ${name}" >&2
    exit 1
  fi
}

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/preview"
DERIVED_DATA_DIR="${BUILD_DIR}/DerivedData"
EXPORT_DIR="${BUILD_DIR}/exported"
APP_NAME="DefaultEditorSwitcher.app"
SOURCE_APP_PATH="${DERIVED_DATA_DIR}/Build/Products/Release/${APP_NAME}"
APP_PATH="${EXPORT_DIR}/${APP_NAME}"
MANIFEST_PATH="${BUILD_DIR}/preview-manifest.txt"

require_command xcodebuild
require_command codesign
require_command ditto

pushd "${ROOT_DIR}" >/dev/null

SHOW_BUILD_SETTINGS="$(
  xcodebuild -scheme DefaultEditorSwitcher -configuration Release -showBuildSettings
)"

MARKETING_VERSION="$(
  printf '%s\n' "${SHOW_BUILD_SETTINGS}" | awk -F' = ' '/ MARKETING_VERSION = / { print $2; exit }'
)"
CURRENT_PROJECT_VERSION="$(
  printf '%s\n' "${SHOW_BUILD_SETTINGS}" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = / { print $2; exit }'
)"

if [[ -z "${MARKETING_VERSION}" || -z "${CURRENT_PROJECT_VERSION}" ]]; then
  echo "Unable to determine MARKETING_VERSION or CURRENT_PROJECT_VERSION from Xcode build settings." >&2
  exit 1
fi

PREVIEW_TAG="v${MARKETING_VERSION}-preview.${CURRENT_PROJECT_VERSION}"
ZIP_NAME="DefaultEditorSwitcher-v${MARKETING_VERSION}-preview.${CURRENT_PROJECT_VERSION}-macOS.zip"
ZIP_PATH="${BUILD_DIR}/${ZIP_NAME}"

rm -rf "${BUILD_DIR}"
mkdir -p "${EXPORT_DIR}"

xcodebuild build \
  -scheme DefaultEditorSwitcher \
  -configuration Release \
  -derivedDataPath "${DERIVED_DATA_DIR}" \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_STYLE=Manual

if [[ ! -d "${SOURCE_APP_PATH}" ]]; then
  echo "Built app not found: ${SOURCE_APP_PATH}" >&2
  exit 1
fi

ditto "${SOURCE_APP_PATH}" "${APP_PATH}"

codesign --force --deep --sign - "${APP_PATH}"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

{
  echo "marketing_version=${MARKETING_VERSION}"
  echo "build_number=${CURRENT_PROJECT_VERSION}"
  echo "tag=${PREVIEW_TAG}"
  echo "release_title=DefaultEditorSwitcher v${MARKETING_VERSION} Preview ${CURRENT_PROJECT_VERSION}"
  echo "signing_mode=adhoc"
  echo "app_path=${APP_PATH}"
  echo "zip_path=${ZIP_PATH}"
} > "${MANIFEST_PATH}"

echo "Preview artifact ready:"
echo "  Tag: ${PREVIEW_TAG}"
echo "  App: ${APP_PATH}"
echo "  Zip: ${ZIP_PATH}"
echo "  Manifest: ${MANIFEST_PATH}"

popd >/dev/null
