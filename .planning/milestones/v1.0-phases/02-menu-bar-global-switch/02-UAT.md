---
status: complete
phase: 02-menu-bar-global-switch
source:
  - 02-01-SUMMARY.md
  - 02-02-SUMMARY.md
  - 02-03-SUMMARY.md
  - ../../quick/260326-18g-12-app/260326-18g-SUMMARY.md
  - ../../quick/260326-1cj-app-12-app-12/260326-1cj-SUMMARY.md
  - ../../quick/260326-1fr-app/260326-1fr-SUMMARY.md
started: 2026-03-25T17:10:57Z
updated: 2026-03-25T17:14:01Z
---

## Current Test

[testing complete]

## Tests

### 1. Menu Bar Residency
expected: Launching the app should show a resident menu bar item and should not open a preferences-first or rules window automatically.
result: pass

### 2. App-Only Dropdown Content
expected: Opening the menu should show the current global editor summary plus app choices only. It should not show extension previews, partial-failure text, or any post-switch feedback row inside the dropdown.
result: pass

### 3. First-Level App Count
expected: The first-level menu should show only checked recommended editors that are currently installed and full-support. It should not backfill other eligible apps to reach 12, and unchecked editors should remain in `More`.
result: pass

### 4. Non-Curated App Ordering
expected: After the fixed recommended apps at the front, non-curated apps in the global menu should be ordered by how many supported developer-text extensions they declare, highest first.
result: pass

### 5. Live Global Switch Readback
expected: Selecting another full-support editor should update the current-state summary and the inline current marker after the write completes, without adding any extra feedback row to the menu.
result: pass

### 6. Rules Window Handoff
expected: `Open Rules Window...` should open the placeholder rules window while the menu bar utility remains available for immediate reuse.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
