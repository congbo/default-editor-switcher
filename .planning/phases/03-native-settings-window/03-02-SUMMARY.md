---
phase: 03-native-settings-window
plan: 02
subsystem: ui
tags: [swiftui, preferences, menu-bar, ranking]
requires:
  - phase: 03-native-settings-window
    provides: settings window shell, stable app-root stores, menu settings action
provides:
  - persisted recommended-app ordering and enablement
  - menu bar first-level rows driven by user-configured recommended apps
  - native recommendation settings controls with reorder actions
affects: [phase-03, menu-bar, editor-ranking, preferences]
tech-stack:
  added: []
  patterns: [preference overlay on curated defaults, user-configurable ranking before catalog fallback]
key-files:
  created:
    - App/Application/Settings/RecommendedMenuAppsStore.swift
    - App/Features/Settings/RecommendedAppsSettingsSection.swift
    - Tests/DefaultEditorSwitcherTests/RecommendedMenuAppsStoreTests.swift
  modified:
    - App/Features/MenuBar/MenuBarViewModel.swift
    - App/Domain/Editors/EditorRankingPolicy.swift
    - App/Support/KnownEditors.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
    - Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
key-decisions:
  - "Recommended app preferences seed from the immutable curated catalog so existing users keep the familiar default order."
  - "Explicit user recommendation order beats catalog ranking, and the menu now shows only checked available recommendations at the first level."
patterns-established:
  - "Persisted recommendation overlays resolve only against currently eligible full-support apps."
  - "Settings-side reorder controls mutate store state; menu composition reacts through published preference changes."
requirements-completed: [MENU-03, DISC-01, DISC-03]
duration: 6 min
completed: 2026-03-26
---

# Phase 3 Plan 02: Recommended Apps Settings Summary

**Recommended menu apps are now persisted, reorderable, and consumed directly by the first-level menu, with unchecked editors moving to `More` instead of being backfilled**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-26T01:56:00+08:00
- **Completed:** 2026-03-26T02:02:00+08:00
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Added a persisted recommended-app store seeded from the existing curated editor order.
- Updated menu composition so the configured recommended order drives the first-level rows without backfill or current-editor injection.
- Exposed native include/exclude and move up/down controls in settings and covered them with regression tests.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Persist recommended-app configuration seeded from the existing curated order** - `working-tree`
2. **Task 2: Make the menu bar honor configured recommended apps without backfill or current-editor injection** - `working-tree`
3. **Task 3: Add a native recommended-app settings section and regression tests** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/Application/Settings/RecommendedMenuAppsStore.swift` - persists ordered and enabled recommended bundle IDs and resolves them against available apps.
- `App/Features/Settings/RecommendedAppsSettingsSection.swift` - exposes native enablement and reorder controls for first-level menu recommendations.
- `App/Features/MenuBar/MenuBarViewModel.swift` - rebuilds primary and overflow rows from persisted recommendation preferences.
- `App/Domain/Editors/EditorRankingPolicy.swift` - honors explicit recommendation overrides before falling back to default catalog ranking.
- `App/Support/KnownEditors.swift` - exposes immutable helpers for seeding the default recommendation order.
- `Tests/DefaultEditorSwitcherTests/RecommendedMenuAppsStoreTests.swift` - verifies seeding, persistence, filtering, and reordering.

## Decisions Made

- Kept the curated editor catalog immutable and introduced a separate store for user customization rather than mutating catalog order directly.
- Limited recommendation resolution to full-support editors so the first-level dropdown cannot be configured into a misleading partial-support state.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Menu recommendation preferences now react live, so language localization can be layered on top without revisiting menu ordering rules.

---
*Phase: 03-native-settings-window*
*Completed: 2026-03-26*
