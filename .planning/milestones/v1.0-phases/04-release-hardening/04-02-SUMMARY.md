---
phase: 04-release-hardening
plan: 02
subsystem: ui
tags: [menu-bar, localization, recovery, release, testing]
requires:
  - phase: 02-menu-bar-global-switch
    provides: global switch report aggregation and menu-bar action flow
  - phase: 03-native-settings-window
    provides: settings-window scene id and app localization pipeline
provides:
  - localized recovery feedback derived from global switch reports
  - menu-bar recovery action that opens Settings
  - installed-artifact verification script and clean-machine checklist
affects: [phase-04, menu-bar, settings-window, distribution, localization]
tech-stack:
  added: [GlobalTextSwitchFeedbackFormatter, verify-installed-app.sh, clean-machine-checklist.md]
  patterns: [report-derived recovery messaging, installed-build validation outside Xcode]
key-files:
  created:
    - App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift
    - Tests/DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests.swift
    - Tools/Release/verify-installed-app.sh
    - Tools/Release/clean-machine-checklist.md
  modified:
    - App/Application/GlobalText/GlobalTextSwitchCoordinator.swift
    - App/Application/GlobalText/GlobalTextSwitchReport.swift
    - App/Features/MenuBar/MenuBarContentView.swift
    - App/Features/MenuBar/MenuBarViewModel.swift
    - App/Resources/Localizable.xcstrings
    - Tests/DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests.swift
    - Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
key-decisions:
  - "Failure messaging stays derived from `GlobalTextSwitchReport` so the product keeps one truth source for switch verification."
  - "Recovery stays inside the existing menu bar and Settings window flow instead of introducing a new release-only UI path."
patterns-established:
  - "Switch failures surface a localized headline plus up to three scope-specific detail lines."
  - "Installed release candidates are validated with trust checks first, then human product checks from a documented clean-machine checklist."
requirements-completed: [DIST-01, DIST-02]
duration: 25 min
completed: 2026-03-26
---

# Phase 4 Plan 02: Failure Recovery and Installed-Build Validation Summary

**The shipped menu bar flow now explains partial switch failures in localized, scope-specific language and the release checklist extends through an installed app build outside Xcode**

## Performance

- **Duration:** 25 min
- **Started:** 2026-03-26T04:43:00+08:00
- **Completed:** 2026-03-26T05:08:00+08:00
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Extended the aggregate switch report so failed samples carry human-readable scope labels such as `.md` or `.py`.
- Added localized recovery formatting plus a menu-bar recovery block that opens `Settings...` directly from the failure state.
- Added installed-artifact verification scripts, a clean-machine checklist, and regression tests covering the new recovery behavior.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Extend global-switch failure data and add a localized feedback formatter** - `working-tree`
2. **Task 2: Surface recovery feedback in the menu bar flow and clear stale warnings after success** - `working-tree`
3. **Task 3: Add installed-artifact verification and a clean-machine release checklist** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `App/Application/GlobalText/GlobalTextSwitchReport.swift` - adds `scopeLabel` to representative failures so the UI can explain which type failed.
- `App/Application/GlobalText/GlobalTextSwitchCoordinator.swift` - derives scope labels from concrete extensions when available.
- `App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift` - converts switch reports into localized recovery copy and detail rows.
- `App/Features/MenuBar/MenuBarViewModel.swift` - publishes `lastSwitchFeedback` and clears stale recovery state after a later full-success apply.
- `App/Features/MenuBar/MenuBarContentView.swift` - renders the recovery block above `More` and opens `settings-window` for remediation.
- `App/Resources/Localizable.xcstrings` - adds English and Simplified Chinese recovery strings.
- `Tests/DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests.swift` - covers localized headline/detail generation.
- `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift` - covers recovery publication and stale-feedback clearing.
- `Tools/Release/verify-installed-app.sh` - validates an installed app bundle and launches it outside Xcode.
- `Tools/Release/clean-machine-checklist.md` - documents the release-candidate trust and product checks for a clean machine.

## Decisions Made

- Limited the recovery details to three failed scopes so the menu stays compact and readable.
- Reused the existing `settings-window` scene as the recovery handoff so failure handling remains consistent with the broader product architecture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Actor isolation] The feedback formatter protocol needed to be main-actor aligned with menu state**
- **Found during:** Task 1 (Extend global-switch failure data and add a localized feedback formatter)
- **Issue:** The formatter is consumed by the menu view model on the main actor, but the protocol initially did not carry that isolation.
- **Fix:** Marked `GlobalTextSwitchFeedbackFormatting` with `@MainActor`.
- **Files modified:** `App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift`
- **Verification:** Full `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` passed after the change.
- **Committed in:** `working-tree`

**2. [Localization correctness] OSStatus output needed deterministic formatting for negative codes**
- **Found during:** Task 1 (Extend global-switch failure data and add a localized feedback formatter)
- **Issue:** Generic numeric interpolation risked locale-specific formatting that obscures raw macOS error codes such as `-10810`.
- **Fix:** Formatted the localized `OSStatus` message with a POSIX locale-aware `String(format:)` path.
- **Files modified:** `App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift`
- **Verification:** `GlobalTextSwitchFeedbackFormatterTests` and the full macOS test suite passed.
- **Committed in:** `working-tree`

---

**Total deviations:** 2 auto-fixed (actor isolation, localization correctness)
**Impact on plan:** Both fixes were necessary for a stable release-facing recovery surface. No scope expansion.

## Issues Encountered

The full suite still emits the existing `AFIsDeviceGreymatterEligible Missing entitlements for os_eligibility lookup` warning during test-host launch, but the suite stays green and the warning does not affect Phase 04 deliverables.

## User Setup Required

Human release verification still needs an actual signed/notarized artifact installed from `/Applications`; the exact steps are captured in `Tools/Release/clean-machine-checklist.md` and `04-HUMAN-UAT.md`.

## Next Phase Readiness

Phase 04 implementation is code-complete and full automated checks are green. The remaining gate before phase completion is the human release-validation set captured in `04-VERIFICATION.md` and `04-HUMAN-UAT.md`.

---
*Phase: 04-release-hardening*
*Completed: 2026-03-26*
