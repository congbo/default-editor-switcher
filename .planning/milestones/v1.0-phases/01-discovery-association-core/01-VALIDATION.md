---
phase: 01
slug: discovery-association-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | `DefaultEditorSwitcher.xcodeproj/project.pbxproj` — none exists yet; Wave 0 creates it |
| **Quick run command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests` |
| **Full suite command** | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 seconds once the project scaffold exists |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests`
- **After every plan wave:** Run `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | GLOB-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/FileScopeCatalogTests` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | GLOB-02 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/FileScopeCatalogTests` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 2 | DISC-01 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/EditorRankingPolicyTests` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 2 | DISC-02, DISC-03 | unit | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/WorkspaceDiscoveryTests` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 3 | DISC-03 | integration | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/LaunchServicesClientTests` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 3 | DISC-03 | manual smoke | `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `DefaultEditorSwitcher.xcodeproj/project.pbxproj` — app and test targets created
- [ ] `Tests/DefaultEditorSwitcherTests/FileScopeCatalogTests.swift` — taxonomy and scope assertions
- [ ] `Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift` — recommendation/ranking assertions
- [ ] `Tests/DefaultEditorSwitcherTests/LaunchServicesClientTests.swift` — adapter and verification behavior tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Launch Services write/readback on representative types | DISC-03 | Mutating the machine’s preferred handlers is unsafe to do blindly in standard unit tests | On a throwaway user or test machine, switch a representative type such as `.txt` or `.md` to a known editor bundle ID, read back the effective handler, then restore the original handler and confirm the pre-test state is back |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
