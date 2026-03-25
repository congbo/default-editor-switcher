---
phase: 03
slug: native-settings-window
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-26
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | none — Xcode project target configuration only |
| **Quick run command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/LaunchAtLoginServiceTests -only-testing:DefaultEditorSwitcherTests/RecommendedMenuAppsStoreTests -only-testing:DefaultEditorSwitcherTests/AppLanguageStoreTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests` |
| **Full suite command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` |
| **Estimated runtime** | ~35 seconds |

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/LaunchAtLoginServiceTests -only-testing:DefaultEditorSwitcherTests/RecommendedMenuAppsStoreTests -only-testing:DefaultEditorSwitcherTests/AppLanguageStoreTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`
- **After every plan wave:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 40 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | DIST-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testOpenSettingsWindowActionIsExposed` | ✅ existing target | ⬜ pending |
| 03-01-02 | 01 | 1 | PROD-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/LaunchAtLoginServiceTests` | ✅ existing target | ⬜ pending |
| 03-02-01 | 02 | 2 | MENU-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testPrimaryRowsRespectConfiguredRecommendedAppOrder` | ✅ existing target | ⬜ pending |
| 03-02-02 | 02 | 2 | DISC-01 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/RecommendedMenuAppsStoreTests` | ✅ existing target | ⬜ pending |
| 03-03-01 | 03 | 3 | app-language | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/AppLanguageStoreTests` | ✅ existing target | ⬜ pending |
| 03-03-02 | 03 | 3 | DIST-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests/testLocalizedMenuLabelsFollowSelectedAppLanguage` | ✅ existing target | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Launch-at-login toggle reflects real system status after enable and disable | PROD-02 | `SMAppService` behavior depends on the running app bundle and local machine state | Build and run the app, open `Settings...`, enable launch at login, close and reopen the settings window, confirm the toggle still reflects enabled state, then disable it and confirm the state refreshes again |
| Recommended menu apps configuration changes the first-level menu ordering and `More` contents immediately | MENU-03, DISC-01 | The menu-bar interaction and post-persist live refresh are best validated in a live app session | Open `Settings...`, change the recommended app order and selection, reopen the menu bar dropdown, and confirm the first-level rows follow the saved order, unchecked editors move to `More`, and the menu no longer backfills to 12 |
| Language selection updates both settings and menu copy consistently | app-language | Locale override behavior across menu-bar and secondary-window scenes is difficult to prove from unit tests alone | Switch the app language from system to English, then to Chinese, reopening the menu if needed; confirm labels such as `Settings...`, section titles, and launch-at-login copy follow the selected language |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 40s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
