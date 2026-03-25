---
status: complete
phase: 04-release-hardening
source:
  - 04-VERIFICATION.md
  - ../../quick/260326-7cf-add-preview-build-packaging-and-github-p/260326-7cf-SUMMARY.md
started: 2026-03-26T05:08:30+0800
updated: 2026-03-26T06:20:30+0800
---

## Current Test

[testing complete]

## Tests

### 1. Preview build packaging
expected: Running `./Tools/Release/build-preview.sh` should build the app in `Release`, ad-hoc sign `build/preview/exported/DefaultEditorSwitcher.app`, create `build/preview/DefaultEditorSwitcher-v1.0-preview.1-macOS.zip`, and write `build/preview/preview-manifest.txt`.
result: pass

### 2. Preview artifact integrity
expected: The exported preview app should pass `codesign --verify --deep --strict --verbose=2`, report `Signature=adhoc`, and the preview zip should unpack into `DefaultEditorSwitcher.app` with `CFBundleShortVersionString = 1.0` and `CFBundleVersion = 1`.
result: pass

### 3. Preview prerelease publishing contract
expected: Running `./Tools/Release/publish-preview.sh --dry-run` after the preview build should resolve the manifest and print the prerelease tag, title, zip path, and manifest path without attempting a live publish.
result: pass

### 4. Automated regression suite
expected: `bash -n` should pass for the release scripts, and `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` should complete with a green suite before preview validation is accepted.
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

No gaps in the adjusted ad-hoc preview verification scope. Formal Developer ID signing, notarization, stapling, and installed `/Applications` Gatekeeper checks remain intentionally unverified in this session.
