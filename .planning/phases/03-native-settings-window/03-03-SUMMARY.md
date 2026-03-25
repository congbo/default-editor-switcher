---
phase: 03-native-settings-window
plan: 03
subsystem: ui
tags: [localization, string-catalog, swiftui, menu-bar]
requires:
  - phase: 03-native-settings-window
    provides: settings window shell, recommendation settings store, shared app-root injection
provides:
  - persisted app-language preference with follow-system default
  - menu and settings localization through a string catalog and app localizer
  - localized settings controls that follow the selected app language
affects: [phase-03, phase-04, localization, settings-window, menu-bar]
tech-stack:
  added: [Localizable.xcstrings]
  patterns: [scene-level locale injection, app-owned copy routed through localization resources]
key-files:
  created:
    - App/Application/Localization/AppLanguage.swift
    - App/Application/Localization/AppLanguageStore.swift
    - App/Features/Settings/LanguageSettingsSection.swift
    - App/Resources/Localizable.xcstrings
    - Tests/DefaultEditorSwitcherTests/AppLanguageStoreTests.swift
  modified:
    - App/DefaultEditorSwitcherApp.swift
    - App/Features/MenuBar/MenuBarContentView.swift
    - App/Features/MenuBar/MenuBarViewModel.swift
    - App/Features/Settings/GeneralSettingsSection.swift
    - App/Features/Settings/RecommendedAppsSettingsSection.swift
    - App/Features/Settings/SettingsWindowView.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
key-decisions:
  - "App-owned strings localize through a dedicated store/localizer pair so menu models can respond to language changes without rebuilding app structure."
  - "Settings detail copy that flows through intermediate values must render as localized keys rather than plain `String` values, otherwise scene locale overrides are bypassed."
patterns-established:
  - "Language preference defaults to follow-system and is injected at the scene root for both menu and settings UI."
  - "Fallback menu summary text is localized in the view model, while static SwiftUI labels use string-catalog-backed keys."
requirements-completed: []
duration: 6 min
completed: 2026-03-26
---

# Phase 3 Plan 03: App Language and Localization Summary

**The app now supports follow-system, English, and Simplified Chinese, and menu/settings copy follows the selected language through a shared string catalog**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-26T02:02:00+08:00
- **Completed:** 2026-03-26T02:08:00+08:00
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Added persisted app language state with follow-system, English, and Simplified Chinese options.
- Localized menu and settings copy through `Localizable.xcstrings` plus a shared app localizer.
- Ensured language changes refresh menu-owned summary and action strings without breaking existing settings and recommendation behavior.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Add persisted app-language state and root locale injection** - `working-tree`
2. **Task 2: Move app-owned menu and settings copy into localization resources** - `working-tree`
3. **Task 3: Add tests proving language preference persistence and localized menu labels** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/Application/Localization/AppLanguage.swift` - defines the supported app-language modes and locale identifiers.
- `App/Application/Localization/AppLanguageStore.swift` - persists language choice and publishes locale-aware app localization changes.
- `App/DefaultEditorSwitcherApp.swift` - injects the selected locale into both menu and settings scenes.
- `App/Features/MenuBar/MenuBarViewModel.swift` - localizes settings action titles and fallback summary strings.
- `App/Features/Settings/LanguageSettingsSection.swift` - exposes the language picker with follow-system, English, and Simplified Chinese options.
- `App/Resources/Localizable.xcstrings` - stores the menu and settings translations used by the app-owned UI.

## Decisions Made

- Kept editor names unlocalized and limited localization to app-owned copy so installed app labels remain truthful to the system.
- Reused the same localization pipeline across menu and settings views to avoid a split between view-model strings and SwiftUI scene locale behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Localization correctness] Settings detail text initially bypassed scene locale overrides**
- **Found during:** Task 2 (Move app-owned menu and settings copy into localization resources)
- **Issue:** Some settings detail strings were stored as plain `String` values before rendering, so they did not switch languages with the selected app locale.
- **Fix:** Converted the affected settings status and recommendation detail paths to render through localized keys.
- **Files modified:** App/Features/Settings/GeneralSettingsSection.swift, App/Features/Settings/RecommendedAppsSettingsSection.swift
- **Verification:** Full `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` passed after the fix.
- **Committed in:** `working-tree`

---

**Total deviations:** 1 auto-fixed (localization correctness)
**Impact on plan:** Necessary for the language-switching feature to be functionally correct. No scope expansion.

## Issues Encountered

The full test suite still emits an AppKit layout recursion warning during test host launch, but tests remain green and this warning was already present during the broader suite run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 03 implementation is code-complete and ready for manual verification. The next milestone step is `gsd-verify-work 03` before moving into release hardening.

---
*Phase: 03-native-settings-window*
*Completed: 2026-03-26*
