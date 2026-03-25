---
status: complete
phase: 03-native-settings-window
source:
  - 03-01-SUMMARY.md
  - 03-02-SUMMARY.md
  - 03-03-SUMMARY.md
started: 2026-03-26T04:27:46+0800
updated: 2026-03-26T04:30:00+0800
---

## Current Test

[testing complete]

## Tests

### 1. Settings Window And Launch At Login
expected: Open `Settings...` from the menu bar. A native settings window should appear instead of the old placeholder rules window. In `General`, toggling launch at login on should succeed, and after closing and reopening the settings window the toggle should still show enabled. Toggling it back off should also succeed and remain off after refresh.
result: pass

### 2. Recommended Menu Apps Configuration
expected: In `Settings...` > `Menu Bar`, changing the recommended editor selection or order should immediately affect the menu bar dropdown. The first-level rows should follow the saved checked order, unchecked editors should move to `More`, and the menu should not backfill extra apps to reach 12.
result: pass

### 3. App Language Localization
expected: In `Settings...` > `Language`, switching between Follow System, English, and Simplified Chinese should update both settings labels and menu copy consistently. Labels such as `Settings...`, section titles, and launch-at-login text should match the selected app language.
result: pass

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
