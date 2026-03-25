---
phase: 04
slug: release-hardening
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-26
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest plus shell syntax validation |
| **Config file** | none — Xcode project target configuration only |
| **Quick run command** | `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh Tools/Release/verify-installed-app.sh && plutil -lint Tools/Release/export-options.plist && xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests` |
| **Full suite command** | `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh Tools/Release/verify-installed-app.sh && plutil -lint Tools/Release/export-options.plist && xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` |
| **Estimated runtime** | ~55 seconds |

## Sampling Rate

- **After every task commit:** Run `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh Tools/Release/verify-installed-app.sh && plutil -lint Tools/Release/export-options.plist && xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests`
- **After every plan wave:** Run `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh Tools/Release/verify-installed-app.sh && plutil -lint Tools/Release/export-options.plist && xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | DIST-01 | shell | `rg -n "CODE_SIGNING_ALLOWED = YES|ENABLE_HARDENED_RUNTIME = YES|CODE_SIGN_STYLE = Manual" DefaultEditorSwitcher.xcodeproj/project.pbxproj && plutil -lint Tools/Release/export-options.plist` | ✅ existing project | ✅ green |
| 04-01-02 | 01 | 1 | DIST-01 | shell | `bash -n Tools/Release/build-release.sh && rg -n "xcodebuild archive|xcodebuild -exportArchive|notarytool submit|stapler staple|ditto -c -k" Tools/Release/build-release.sh` | ✅ added in phase | ✅ green |
| 04-01-03 | 01 | 1 | DIST-01 | shell | `bash -n Tools/Release/verify-artifact.sh && rg -n "codesign --verify|spctl -a -vv|notarytool log|stapler validate" Tools/Release/verify-artifact.sh Tools/Release/README.md` | ✅ added in phase | ✅ green |
| 04-02-01 | 02 | 2 | DIST-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests` | ✅ existing target | ✅ green |
| 04-02-02 | 02 | 2 | DIST-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests` | ✅ existing target | ✅ green |
| 04-02-03 | 02 | 2 | DIST-01 | shell | `bash -n Tools/Release/verify-installed-app.sh && rg -n "open -na|pgrep -x|spctl -a -vv|codesign --verify" Tools/Release/verify-installed-app.sh Tools/Release/clean-machine-checklist.md` | ✅ added in phase | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Notarized zip installs and launches outside Xcode | DIST-01 | Real notarization credentials, Gatekeeper state, and `/Applications` install behavior cannot be proven in unit tests | Run `Tools/Release/build-release.sh` with real credentials, unzip the artifact, move `DefaultEditorSwitcher.app` into `/Applications`, then run `Tools/Release/verify-installed-app.sh /Applications/DefaultEditorSwitcher.app` |
| Menu shows actionable scope-specific recovery guidance after a partial or failed switch | DIST-02 | Launch Services failure behavior depends on real installed editors and system state | Launch the installed release build, attempt one successful global switch, then trigger or simulate a failure case and confirm the menu lists failed scopes plus a recovery action that opens `Settings...` |
| Signed artifact and notarization ticket remain valid after stapling and rezipping | DIST-01 | Requires real notarization acceptance and post-staple artifact handling | After `build-release.sh` finishes, run `Tools/Release/verify-artifact.sh` against the exported app and final zip, then unzip again and confirm `spctl -a -vv --type execute` still accepts the app |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated verification complete; human release verification pending
