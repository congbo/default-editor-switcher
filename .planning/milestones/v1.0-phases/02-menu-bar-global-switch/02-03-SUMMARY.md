---
phase: 02-menu-bar-global-switch
plan: 03
subsystem: ui
tags: [swiftui, feedback, rules-window, menu-bar]
requires:
  - phase: 02-menu-bar-global-switch
    provides: resident menu shell, batch apply coordinator, structured switch report
provides:
  - current-state refresh without dropdown feedback rows
  - inline current-editor markers and lower-confidence notes
  - rules-window placeholder handoff from the menu footer
affects: [phase-02, phase-04, menu-bar, rules-window]
tech-stack:
  added: []
  patterns: [dropdown stays focused on app choices, secondary window handoff via stable scene id]
key-files:
  created:
    - App/Features/MenuBar/RulesWindowPlaceholderView.swift
  modified:
    - App/DefaultEditorSwitcherApp.swift
    - App/Features/MenuBar/MenuBarContentView.swift
    - App/Features/MenuBar/MenuBarViewModel.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
key-decisions:
  - "The dropdown stays focused on app choices and current-state refresh instead of rendering any success or failure feedback row."
  - "The footer action targets a stable `rules-window` scene id so the app remains menu-bar-first while exposing a real secondary window."
patterns-established:
  - "Top-level menu density is capped so high-frequency recommended actions stay within a short scan."
  - "Current-editor state is indicated on the relevant row without forcing that row into the first-level action list."
  - "Rules-window access is exposed through a simple view-facing action model instead of ad hoc environment calls spread through tests."
requirements-completed: [MENU-03, DIST-03]
duration: 9 min
completed: 2026-03-25
---

# Phase 2 Plan 03: Feedback and Rules Window Summary

**Inline current markers, compact app-only dropdown behavior, and a real rules-window escape hatch for the resident utility**

## Performance

- **Duration:** 9 min
- **Started:** 2026-03-25T14:18:00Z
- **Completed:** 2026-03-25T14:27:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Kept the dropdown focused on app selection and current-state refresh instead of showing post-switch feedback copy.
- Marked the effective current editor inline and added explicit capability notes for lower-confidence rows.
- Wired `Open Rules Window...` to a real placeholder window scene and covered that handoff in tests.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Render compact dropdown behavior and explicit current-editor markers** - `working-tree`
2. **Task 2: Add the rules-window placeholder and window-opening action** - `working-tree`
3. **Task 3: Add tests for feedback text and rules-window exposure** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/Features/MenuBar/MenuBarContentView.swift` - renders summary, feedback, grouped editor rows, and the footer window action in the required order.
- `App/Features/MenuBar/MenuBarViewModel.swift` - translates switch reports into exact feedback copy and current-row state.
- `App/Features/MenuBar/RulesWindowPlaceholderView.swift` - provides the phase-appropriate placeholder for advanced rules.
- `App/DefaultEditorSwitcherApp.swift` - hosts the `rules-window` scene used by the footer action.
- `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift` - covers success/failure feedback copy and rules-window exposure.

## Decisions Made
- Kept the placeholder window explicit about advanced language and custom extension rules arriving in later phases so it reads as intentional rather than unfinished.
- Left refresh behavior tied to menu load and post-apply reload instead of adding another menu row that would break the locked phase order.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 2 implementation is code-complete. Remaining work before phase completion is the manual verification set captured in `02-HUMAN-UAT.md`.

---
*Phase: 02-menu-bar-global-switch*
*Completed: 2026-03-25*
