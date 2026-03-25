#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [--dry-run]" >&2
}

require_command() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Missing required command: ${name}" >&2
    exit 1
  fi
}

manifest_value() {
  local key="$1"
  awk -F= -v key="${key}" '$1 == key { sub(/^[^=]*=/, "", $0); print $0; exit }' "${MANIFEST_PATH}"
}

DRY_RUN=false
if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
  else
    usage
    exit 1
  fi
fi

require_command gh

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/preview"
MANIFEST_PATH="${BUILD_DIR}/preview-manifest.txt"

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "Preview manifest not found: ${MANIFEST_PATH}" >&2
  echo "Run ./Tools/Release/build-preview.sh first." >&2
  exit 1
fi

TAG="$(manifest_value tag)"
RELEASE_TITLE="$(manifest_value release_title)"
MARKETING_VERSION="$(manifest_value marketing_version)"
BUILD_NUMBER="$(manifest_value build_number)"
ZIP_PATH="$(manifest_value zip_path)"
SIGNING_MODE="$(manifest_value signing_mode)"

if [[ -z "${TAG}" || -z "${RELEASE_TITLE}" || -z "${ZIP_PATH}" ]]; then
  echo "Preview manifest is missing required fields." >&2
  exit 1
fi

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Preview zip not found: ${ZIP_PATH}" >&2
  echo "Run ./Tools/Release/build-preview.sh first." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

NOTES_FILE="$(mktemp)"
cleanup() {
  rm -f "${NOTES_FILE}"
}
trap cleanup EXIT

cat > "${NOTES_FILE}" <<EOF
Preview build for DefaultEditorSwitcher ${MARKETING_VERSION} (${BUILD_NUMBER}).

Warnings:
- This is a preview build.
- It is ad-hoc signed, not notarized.
- macOS may warn on first launch.
- Recommended first-run path is right-click "Open".

This prerelease is intended for evaluation and limited testing, not trusted general distribution.
EOF

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run only. Would publish GitHub prerelease:"
  echo "  Tag: ${TAG}"
  echo "  Title: ${RELEASE_TITLE}"
  echo "  Zip: ${ZIP_PATH}"
  echo "  Manifest: ${MANIFEST_PATH}"
  exit 0
fi

if gh release view "${TAG}" >/dev/null 2>&1; then
  gh release edit "${TAG}" \
    --prerelease \
    --title "${RELEASE_TITLE}" \
    --notes-file "${NOTES_FILE}"
  gh release upload "${TAG}" "${ZIP_PATH}" "${MANIFEST_PATH}" --clobber
else
  gh release create "${TAG}" "${ZIP_PATH}" "${MANIFEST_PATH}" \
    --prerelease \
    --title "${RELEASE_TITLE}" \
    --notes-file "${NOTES_FILE}"
fi

echo "Preview prerelease ready:"
echo "  Tag: ${TAG}"
echo "  Title: ${RELEASE_TITLE}"
