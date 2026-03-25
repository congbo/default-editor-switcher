---
status: partial
phase: 01-discovery-association-core
source: [01-VERIFICATION.md]
started: 2026-03-25T12:14:05Z
updated: 2026-03-25T12:14:05Z
---

## Current Test

number: 1
name: Full Xcode Build/Test Pass
expected: |
  `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
  and `xcodebuild build -scheme AssociationProbe -destination 'platform=macOS'`
  both succeed with a full Xcode installation selected.
awaiting: user response

## Tests

### 1. Full Xcode Build/Test Pass
expected: `DefaultEditorSwitcher` tests pass and `AssociationProbe` builds in a full Xcode environment.
result: pending

### 2. Association Probe Smoke Run
expected: Running `AssociationProbe --extension <txt|md> --bundle-id <known-editor> --restore-bundle-id <original>` prints `requested=...`, `effective=...`, `status=matched`, then restores the original handler.
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
