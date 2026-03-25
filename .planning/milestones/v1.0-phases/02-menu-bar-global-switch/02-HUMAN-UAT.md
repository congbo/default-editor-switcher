---
status: passed
phase: 02-menu-bar-global-switch
source: [02-VERIFICATION.md]
started: 2026-03-25T14:21:35Z
updated: 2026-03-25T14:54:49Z
---

## Current Test

Human verification completed and passed.

## Tests

### 1. Menu bar residency and launch behavior
expected: Launching the app shows a menu bar item and does not open a preferences-first main window.
result: [passed] Menu bar item appears on launch and the app does not open a preferences-first main window.

### 2. Live global switch readback
expected: Selecting another full-support editor updates the current-state summary and the inline `Current` marker after the write completes.
result: [passed] Live switching works, the actual current editor is shown, and the inline `Current` marker reflects the active default after refresh.

### 3. Rules window handoff
expected: `Open Rules Window...` opens the placeholder window while the menu bar utility remains available for immediate reuse.
result: [passed] Rules window opens successfully from the menu bar utility.

### 4. Menu panel stability
expected: Opening the menu does not emit the AppKit layout recursion warning and the current editor remains visible in the summary.
result: [passed] The `-layoutSubtreeIfNeeded` warning no longer appears and the summary shows the actual current editor.

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
