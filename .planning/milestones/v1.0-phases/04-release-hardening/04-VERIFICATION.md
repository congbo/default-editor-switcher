---
phase: 04-release-hardening
verified: 2026-03-26T08:47:00+08:00
status: passed
score: 3/3 phase truths verified against the final v1.0 release contract
---

# Phase 4: Release Hardening Verification Report

**Phase Goal:** Ship a trustworthy direct-download macOS product with clear failure handling and validated release artifacts.
**Verified:** 2026-03-26T08:47:00+08:00
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Association failures show actionable messages that identify the failed scope and recovery path. | ✓ VERIFIED | `App/Application/GlobalText/GlobalTextSwitchReport.swift` now carries `scopeLabel`, `App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift` formats localized recovery copy, `App/Features/MenuBar/MenuBarContentView.swift` renders the recovery block with `Open Settings for Recovery`, and `GlobalTextSwitchFeedbackFormatterTests` plus `MenuBarViewModelTests` cover the flow. |
| 2 | Release validation covers signed/notarized behavior through repo-owned scripts and installed-app checks instead of debug-only workflows. | ✓ VERIFIED | `Tools/Release/build-release.sh`, `verify-artifact.sh`, `verify-installed-app.sh`, and `clean-machine-checklist.md` define the end-to-end direct-download release and install verification contract; `bash -n` and `plutil -lint` passed. |
| 3 | The v1.0 release contract is a verified direct-download preview release candidate today, with the exact Developer ID notarization path documented for later GA execution on a credentialed machine. | ✓ VERIFIED | `04-HUMAN-UAT.md` passed the preview packaging, artifact-integrity, prerelease-publishing, and regression checks; `Tools/Release/build-release.sh`, `verify-artifact.sh`, and `verify-installed-app.sh` document the later credentialed Developer ID path; `REQUIREMENTS.md` rebaselines `DIST-01` to this contract in Phase 05. |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `DefaultEditorSwitcher.xcodeproj/project.pbxproj` | Release signing and hardened runtime for the app target | ✓ EXISTS + SUBSTANTIVE | App target Release config enables `CODE_SIGNING_ALLOWED`, `CODE_SIGNING_REQUIRED`, manual signing, `Developer ID Application`, and hardened runtime while non-shipping targets stay unsigned. |
| `Tools/Release/export-options.plist` | Developer ID export contract | ✓ EXISTS + SUBSTANTIVE | Defines a direct-distribution export using the developer-id method. |
| `Tools/Release/build-release.sh` | Single release operator entrypoint | ✓ EXISTS + SUBSTANTIVE | Archives, exports, zips, notarizes, staples, re-zips, and records a release manifest under `build/release/`. |
| `Tools/Release/verify-artifact.sh` | Pre-install trust verification | ✓ EXISTS + SUBSTANTIVE | Checks codesign integrity, Gatekeeper acceptance, stapling, and notarization evidence from the manifest. |
| `Tools/Release/verify-installed-app.sh` | Installed-app trust and launch verification | ✓ EXISTS + SUBSTANTIVE | Verifies codesign/spctl, launches the installed app, and checks the process is running. |
| `Tools/Release/clean-machine-checklist.md` | Human release-candidate checklist | ✓ EXISTS + SUBSTANTIVE | Documents the ordered clean-machine flow from build through failure-recovery UI checks. |
| `App/Features/MenuBar/GlobalTextSwitchFeedbackFormatter.swift` | Localized failure-to-feedback mapping | ✓ EXISTS + SUBSTANTIVE | Generates a headline, detail lines, and recovery CTA from `GlobalTextSwitchReport`. |
| `App/Features/MenuBar/MenuBarViewModel.swift` | Published recovery state | ✓ EXISTS + SUBSTANTIVE | Publishes `lastSwitchFeedback` only for affected reports and clears it after a later successful switch. |
| `App/Features/MenuBar/MenuBarContentView.swift` | Recovery presentation in the menu | ✓ EXISTS + SUBSTANTIVE | Renders the feedback block above `More` and routes recovery into `settings-window`. |
| `Tests/DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests.swift` | Formatter regression coverage | ✓ EXISTS + SUBSTANTIVE | Verifies localized headline/detail mapping and no-op behavior on full success. |
| `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift` | Recovery state regression coverage | ✓ EXISTS + SUBSTANTIVE | Verifies recovery publication and stale-feedback clearing. |

**Artifacts:** 11/11 verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `GlobalTextSwitchCoordinator.swift` | `GlobalTextSwitchReport.swift` | `scopeLabel` population | ✓ WIRED | Failed samples now carry extension-first scope labels such as `.md`, `.py`, and `.rs`. |
| `GlobalTextSwitchFeedbackFormatter.swift` | `Localizable.xcstrings` | localized recovery strings | ✓ WIRED | Formatter resolves the new headline, detail, and CTA strings from the string catalog. |
| `MenuBarViewModel.swift` | `GlobalTextSwitchFeedbackFormatter.swift` | `lastSwitchFeedback` derivation | ✓ WIRED | The view model converts the latest report into published recovery state and clears it after full success. |
| `MenuBarContentView.swift` | `DefaultEditorSwitcherApp.swift` | `openWindow(id: "settings-window")` | ✓ WIRED | The recovery CTA reuses the existing Settings scene instead of inventing a new recovery window. |
| `Tools/Release/build-release.sh` | `Tools/Release/verify-artifact.sh` | `build/release/release-manifest.txt` | ✓ WIRED | The build script emits manifest data that the artifact verifier reads for notarization evidence. |
| `Tools/Release/clean-machine-checklist.md` | `Tools/Release/verify-installed-app.sh` | installed-app validation step | ✓ WIRED | The release checklist routes operators through the installed-build script after moving the app into `/Applications`. |

**Wiring:** 6/6 connections verified

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| DIST-01: Team can produce and validate a direct-download preview release candidate outside the Mac App Store, while the repo documents the Developer ID notarization path required for later GA shipping | ✓ SATISFIED | - |
| DIST-02: When an association update fails fully or partially, the app shows an actionable error with the affected scope and a recovery path | ✓ SATISFIED | - |

**Coverage:** 2 satisfied

## Human Verification

1. Preview build packaging passed in `04-HUMAN-UAT.md`.
2. Preview artifact integrity checks passed in `04-HUMAN-UAT.md`.
3. Preview prerelease publishing contract passed in `04-HUMAN-UAT.md`.
4. Full automated regression checks passed before the preview validation was accepted.

## Gaps Summary

No Phase 04 implementation gaps remain. The original credentialed notarization install run is preserved as documented operator follow-up, but it is no longer a v1.0 archival blocker after the explicit `DIST-01` rebaseline in Phase 05.

## Verification Metadata

**Verification approach:** Goal-backward from the Phase 4 roadmap goal, plan must-haves, and validation strategy.
**Must-haves source:** `04-01-PLAN.md`, `04-02-PLAN.md`, and the Phase 4 success criteria in `ROADMAP.md`.
**Automated checks:** `bash -n Tools/Release/build-release.sh Tools/Release/verify-artifact.sh Tools/Release/verify-installed-app.sh`, `plutil -lint Tools/Release/export-options.plist`, and `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` all passed.
**Human checks required:** 0 remaining
**Total verification time:** 14m

---
*Verified: 2026-03-26T08:47:00+08:00*
*Verifier: Codex*
