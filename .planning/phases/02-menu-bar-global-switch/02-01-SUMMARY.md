---
phase: 02-menu-bar-global-switch
plan: 01
subsystem: ui
tags: [swiftui, menubarextra, launchservices, menu-bar]
requires:
  - phase: 01-discovery-association-core
    provides: content-type resolution, editor discovery, Launch Services verification primitives
provides:
  - resident MenuBarExtra app shell
  - global text current-state aggregation service
  - grouped menu row models and load-time menu view model
affects: [phase-02, phase-03, menu-bar, rules-window]
tech-stack:
  added: []
  patterns: [service-backed menu bar view model, aggregated global text state]
key-files:
  created:
    - App/Application/GlobalText/GlobalTextStateService.swift
    - App/Features/MenuBar/MenuBarContentView.swift
    - App/Features/MenuBar/MenuBarSection.swift
    - App/Features/MenuBar/MenuBarViewModel.swift
    - Tests/DefaultEditorSwitcherTests/GlobalTextStateServiceTests.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
  modified:
    - App/DefaultEditorSwitcherApp.swift
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
key-decisions:
  - "Global text current state is aggregated across all declared developer-text UTTypes instead of inferred from a single sample extension."
  - "Menu rows are grouped into recommended full-support, other eligible, and needs-verification sections so lower-confidence editors do not look like primary actions."
patterns-established:
  - "MenuBarContentView stays declarative and renders view-model-owned summary, feedback, and grouped action rows."
  - "GlobalTextStateService deduplicates UTTypes before inspection so shared content types do not distort current-state reporting."
requirements-completed: [MENU-01, MENU-02]
duration: 12 min
completed: 2026-03-25
---

# Phase 2 Plan 01: Menu Bar Shell and Read Model Summary

**Resident menu bar shell with truthful global-text state aggregation and ranked editor sections**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-25T13:55:00Z
- **Completed:** 2026-03-25T14:07:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Converted the app entry point into a resident `MenuBarExtra` shell with a real `rules-window` scene hook.
- Added `GlobalTextStateService` to aggregate the full developer-text scope into single, mixed, or unavailable current-state summaries.
- Built menu row and section models plus unit tests that verify summary loading and full-support-first ordering.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Convert the app entry into a resident MenuBarExtra shell** - `working-tree`
2. **Task 2: Implement a global-text state service and menu section model** - `working-tree`
3. **Task 3: Add tests for current-state aggregation and menu loading** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/DefaultEditorSwitcherApp.swift` - switches the app to a menu bar utility and wires the `rules-window` scene.
- `App/Application/GlobalText/GlobalTextStateService.swift` - reads all declared `.allText` content types and collapses them into a current-state summary.
- `App/Features/MenuBar/MenuBarSection.swift` - defines summary and row models for recommended, other eligible, and needs-verification sections.
- `App/Features/MenuBar/MenuBarViewModel.swift` - loads current state and ranked editor candidates for the menu shell.
- `App/Features/MenuBar/MenuBarContentView.swift` - renders summary-first menu content with grouped editor sections and footer action.
- `Tests/DefaultEditorSwitcherTests/GlobalTextStateServiceTests.swift` - covers single, mixed, and unavailable aggregation cases.
- `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift` - covers menu loading and section ordering.

## Decisions Made
- Used `.plainText` as the representative discovery type for menu candidates while reading current state from the full declared developer-text scope.
- Kept the rules window real at the scene level in Phase 2, but left detailed rule editing for later phases.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `02-02`: the menu shell, current-state summary, and ranked candidate list are in place for wiring the real batch-apply path.

---
*Phase: 02-menu-bar-global-switch*
*Completed: 2026-03-25*
