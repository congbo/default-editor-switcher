#!/usr/bin/env bash

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

require_env DEVELOPMENT_TEAM_ID
require_env CODE_SIGN_IDENTITY
require_env NOTARY_PROFILE

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/release"
ARCHIVE_PATH="${BUILD_DIR}/DefaultEditorSwitcher.xcarchive"
EXPORT_DIR="${BUILD_DIR}/exported"
APP_PATH="${EXPORT_DIR}/DefaultEditorSwitcher.app"
ZIP_PATH="${BUILD_DIR}/DefaultEditorSwitcher-macOS-Universal.zip"
MANIFEST_PATH="${BUILD_DIR}/release-manifest.txt"
EXPORT_OPTIONS_PLIST="${ROOT_DIR}/Tools/Release/export-options.plist"

mkdir -p "${BUILD_DIR}"
rm -rf "${ARCHIVE_PATH}" "${EXPORT_DIR}" "${ZIP_PATH}" "${MANIFEST_PATH}"

pushd "${ROOT_DIR}" >/dev/null

xcodebuild archive \
  -scheme DefaultEditorSwitcher \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
  ENABLE_HARDENED_RUNTIME=YES

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_DIR}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM_ID}" \
  CODE_SIGN_STYLE=Manual

ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

NOTARY_OUTPUT="$(
  xcrun notarytool submit "${ZIP_PATH}" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait \
    --output-format json
)"

SUBMISSION_ID="$(printf '%s' "${NOTARY_OUTPUT}" | plutil -extract id raw -o - - 2>/dev/null || true)"

xcrun stapler staple "${APP_PATH}"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

{
  echo "archive_path=${ARCHIVE_PATH}"
  echo "export_dir=${EXPORT_DIR}"
  echo "app_path=${APP_PATH}"
  echo "zip_path=${ZIP_PATH}"
  echo "development_team_id=${DEVELOPMENT_TEAM_ID}"
  echo "code_sign_identity=${CODE_SIGN_IDENTITY}"
  echo "notary_profile=${NOTARY_PROFILE}"
  echo "submission_id=${SUBMISSION_ID}"
  echo "notary_output=${NOTARY_OUTPUT}"
} > "${MANIFEST_PATH}"

echo "Release artifact ready:"
echo "  App: ${APP_PATH}"
echo "  Zip: ${ZIP_PATH}"
echo "  Manifest: ${MANIFEST_PATH}"

popd >/dev/null
