---
phase: 02
slug: menu-bar-global-switch
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-25
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | none — Xcode project target configuration only |
| **Quick run command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextStateServiceTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests` |
| **Full suite command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` |
| **Estimated runtime** | ~25 seconds |

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextStateServiceTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`
- **After every plan wave:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | MENU-01 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testLoadsCurrentStateAndCandidateSections` | ✅ existing target | ⬜ pending |
| 02-01-02 | 01 | 1 | MENU-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextStateServiceTests` | ✅ existing target | ⬜ pending |
| 02-02-01 | 02 | 2 | GLOB-01 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests/testApplyWritesAllDeclaredTypes` | ✅ existing target | ⬜ pending |
| 02-02-02 | 02 | 2 | GLOB-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests/testAggregateReportCountsMatchedAndFailedResults` | ✅ existing target | ⬜ pending |
| 02-03-01 | 03 | 3 | MENU-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testApplyKeepsLatestReportWithoutPublishingMenuFeedback` | ✅ existing target | ⬜ pending |
| 02-03-02 | 03 | 3 | DIST-03 | unit + manual | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testOpenRulesWindowActionIsExposed` | ✅ existing target | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Menu bar entry is visible and opens without launching a preferences-first window | MENU-01 | Scene behavior and macOS menu bar residency need an actual app run | Build and run the app, confirm a menu bar item appears, click it, and verify the first visible block is the current-state summary instead of a window launch |
| One-click switch updates the current-state summary inside the menu | MENU-03, GLOB-03 | Launch Services writes and menu refresh behavior must be observed on the local machine | Open the menu, choose a different full-support editor row, and verify the summary and inline `Current` marker move to the selected editor without any extra feedback row appearing |
| `Open Rules Window...` opens a secondary window while the app remains a menu bar utility | DIST-03 | Window activation and resident-utility behavior require a live app session | From the menu, choose `Open Rules Window...`, confirm a window opens with placeholder copy, then re-open the menu bar item without relaunching the app |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
