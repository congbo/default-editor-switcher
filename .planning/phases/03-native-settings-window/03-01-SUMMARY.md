---
phase: 03-native-settings-window
plan: 01
subsystem: ui
tags: [swiftui, service-management, settings-window, menu-bar]
requires:
  - phase: 02-menu-bar-global-switch
    provides: resident menu shell, secondary window entry point, current state loading
provides:
  - native settings window scene with stable `settings-window` identifier
  - launch-at-login service boundary around `SMAppService.mainApp`
  - general settings toggle state with error-aware view model
affects: [phase-03, phase-04, settings-window, startup]
tech-stack:
  added: [ServiceManagement]
  patterns: [service-backed settings toggle, stable settings scene id]
key-files:
  created:
    - App/Application/Startup/LaunchAtLoginService.swift
    - App/Application/Startup/GeneralSettingsViewModel.swift
    - App/Features/Settings/SettingsWindowView.swift
    - App/Features/Settings/GeneralSettingsSection.swift
  modified:
    - App/DefaultEditorSwitcherApp.swift
    - App/Features/MenuBar/MenuBarViewModel.swift
    - App/Features/MenuBar/MenuBarSection.swift
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
    - Tests/DefaultEditorSwitcherTests/LaunchAtLoginServiceTests.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
key-decisions:
  - "The placeholder rules window was replaced by a real `settings-window` scene so later settings features layer onto a stable native shell."
  - "Launch at login flows through a dedicated service and view model instead of binding `SMAppService` directly from SwiftUI."
patterns-established:
  - "Settings features use app-owned stores and view models injected from the app root."
  - "Menu footer window actions stay stable even when the backing scene implementation changes."
requirements-completed: [DIST-03, PROD-02]
duration: 6 min
completed: 2026-03-26
---

# Phase 3 Plan 01: Settings Shell and Launch at Login Summary

**A real native settings window now replaces the placeholder rules window and exposes launch-at-login through a testable ServiceManagement boundary**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-26T01:50:00+08:00
- **Completed:** 2026-03-26T01:56:00+08:00
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Replaced the placeholder secondary window flow with a real `settings-window` scene and SwiftUI settings shell.
- Added `LaunchAtLoginService` and `GeneralSettingsViewModel` so startup behavior is read and written through a dedicated service boundary.
- Covered the new settings window action and launch-at-login success and failure paths with tests.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Replace the placeholder rules window with a real settings window shell** - `working-tree`
2. **Task 2: Implement launch-at-login service and general-settings state** - `working-tree`
3. **Task 3: Add tests for launch-at-login behavior and settings-window action wiring** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/DefaultEditorSwitcherApp.swift` - owns shared settings stores and mounts the stable `settings-window` scene.
- `App/Application/Startup/LaunchAtLoginService.swift` - wraps `SMAppService.mainApp` status and enable/disable operations.
- `App/Application/Startup/GeneralSettingsViewModel.swift` - mediates toggle state, loading, and launch-at-login errors.
- `App/Features/Settings/SettingsWindowView.swift` - provides the native settings shell with `General`, `Menu Bar`, and `Language` sections.
- `App/Features/Settings/GeneralSettingsSection.swift` - renders the launch-at-login toggle and explanatory copy.
- `Tests/DefaultEditorSwitcherTests/LaunchAtLoginServiceTests.swift` - verifies register, unregister, and surfaced error behavior.

## Decisions Made

- Renamed the menu action backing identifier from `rules-window` to `settings-window` so the UI model matches the actual product direction.
- Loaded launch-at-login state on settings appearance instead of optimistic toggle-only state, so the UI always reflects system truth.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The native settings shell is in place and can safely accept menu recommendation controls and app language settings in the next plans.

---
*Phase: 03-native-settings-window*
*Completed: 2026-03-26*
