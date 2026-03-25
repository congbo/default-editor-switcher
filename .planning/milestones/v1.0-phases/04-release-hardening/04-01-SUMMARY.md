---
phase: 04-release-hardening
plan: 01
subsystem: infra
tags: [release, codesign, notarization, xcodebuild, macos]
requires:
  - phase: 03-native-settings-window
    provides: shipping-ready app target, settings window scene, and localized product shell
provides:
  - Developer ID release signing on the app target
  - repo-owned archive/export/notarize/staple pipeline
  - scriptable pre-install artifact verification plus operator docs
affects: [phase-04, release, distribution, notarization]
tech-stack:
  added: [Tools/Release/export-options.plist, Tools/Release/build-release.sh, Tools/Release/verify-artifact.sh]
  patterns: [repo-owned release automation, pre-install artifact verification]
key-files:
  created:
    - Tools/Release/export-options.plist
    - Tools/Release/build-release.sh
    - Tools/Release/verify-artifact.sh
    - Tools/Release/README.md
  modified:
    - DefaultEditorSwitcher.xcodeproj/project.pbxproj
key-decisions:
  - "Only the shipping app target is signed in Release; test and probe targets stay unsigned so local validation remains frictionless."
  - "The repository owns the direct-download release path end-to-end so shipping does not depend on Organizer memory or ad hoc shell history."
patterns-established:
  - "Release artifacts are produced under `build/release/` from a single operator entrypoint."
  - "Artifact trust is checked before install with `codesign`, `spctl`, `stapler`, and notarization log evidence."
requirements-completed: [DIST-01]
duration: 8 min
completed: 2026-03-26
---

# Phase 4 Plan 01: Release Pipeline Summary

**Developer ID signing, notarization, and pre-install artifact verification are now scripted from the repository instead of being left to manual Organizer flows**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-26T04:35:00+08:00
- **Completed:** 2026-03-26T04:43:00+08:00
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Enabled Release signing and hardened runtime on the shipping app target while keeping test-only targets unsigned.
- Added a single `build-release.sh` entrypoint that archives, exports, zips, notarizes, staples, and records release metadata under `build/release/`.
- Added `verify-artifact.sh` plus `Tools/Release/README.md` so release operators can validate signing and notarization before installation.

## Task Commits

Atomic task commits were not created in this run. The task outputs are present in the working tree and summarized here:

1. **Task 1: Enable release signing and export settings for the app target** - `working-tree`
2. **Task 2: Create a single release script for archive, export, zip, notarize, and staple** - `working-tree`
3. **Task 3: Add pre-install artifact verification and release operator documentation** - `working-tree`

**Plan metadata:** `working-tree`

## Files Created/Modified
- `DefaultEditorSwitcher.xcodeproj/project.pbxproj` - enables manual Developer ID signing and hardened runtime on the app target's Release configuration.
- `Tools/Release/export-options.plist` - defines the direct-distribution export contract for `xcodebuild -exportArchive`.
- `Tools/Release/build-release.sh` - runs archive, export, zip, notarize, staple, re-zip, and manifest generation.
- `Tools/Release/verify-artifact.sh` - checks the exported app and final zip for signing, stapling, Gatekeeper acceptance, and notarization evidence.
- `Tools/Release/README.md` - documents required credentials, commands, and expected outputs under `build/release/`.

## Decisions Made

- Passed release credentials through environment variables so the repo stays portable across developer and CI release machines.
- Kept the exported artifact path stable under `build/release/` so later installed-app checks and release checklists can consume it without extra operator judgment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Validation compatibility] Release scripts were made bash-compatible instead of shell-dependent**
- **Found during:** Task 2 (Create a single release script for archive, export, zip, notarize, and staple)
- **Issue:** The validation contract linted the release scripts with `bash -n`, so shell-specific assumptions would have created false negatives.
- **Fix:** Standardized the scripts on `#!/usr/bin/env bash` and bash-compatible syntax.
- **Files modified:** `Tools/Release/build-release.sh`, `Tools/Release/verify-artifact.sh`
- **Verification:** `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh` passed.
- **Committed in:** `working-tree`

---

**Total deviations:** 1 auto-fixed (validation compatibility)
**Impact on plan:** Necessary for the release scripts to satisfy the repo's own validation entrypoint. No scope expansion.

## Issues Encountered

None.

## User Setup Required

Release operators still need a valid `Developer ID Application` certificate plus a stored `notarytool` keychain profile before running `build-release.sh`.

## Next Phase Readiness

The release pipeline is in place and verified syntactically. Remaining work for Phase 04 is the failure-recovery UX plus the human release checks captured in `04-VERIFICATION.md` and `04-HUMAN-UAT.md`.

---
*Phase: 04-release-hardening*
*Completed: 2026-03-26*
