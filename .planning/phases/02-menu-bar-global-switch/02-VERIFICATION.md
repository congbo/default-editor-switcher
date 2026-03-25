---
phase: 02-menu-bar-global-switch
verified: 2026-03-25T14:21:35Z
status: passed
score: 6/6 must-haves verified in code and automated tests; human checks passed
---

# Phase 2: Menu Bar Global Switch Verification Report

**Phase Goal:** Deliver the simple `default-browser`-style menu bar flow for switching all text-like files to one editor.
**Verified:** 2026-03-25T14:21:35Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The app launches as a resident menu bar utility with a visible `MenuBarExtra` entry. | ✓ VERIFIED | `App/DefaultEditorSwitcherApp.swift` defines `MenuBarExtra("Default Editor Switcher", systemImage: "slider.horizontal.3")`, and live UAT confirmed the menu bar item appears without opening a preferences-first window. |
| 2 | Opening the menu shows a current global editor summary derived from the full developer-text scope, not a single sample extension. | ✓ VERIFIED | `App/Application/GlobalText/GlobalTextStateService.swift` expands `ContentTypeResolver.resolutions(for: .allText)`, deduplicates declared UTTypes, and returns `.single`, `.mixed`, or `.unavailable`; `Tests/DefaultEditorSwitcherTests/GlobalTextStateServiceTests.swift` covers all three states. |
| 3 | The menu lists recommended full-support editors before lower-priority eligible editors, backfills the first-level list to 12 app choices when enough eligible apps exist, orders non-curated global candidates by supported developer-text extension count, and keeps `Kiro` immediately after `Cursor` in the curated global order. | ✓ VERIFIED | `App/Features/MenuBar/MenuBarViewModel.swift` limits top-level primary rows to 12 while backfilling with non-curated eligible apps when the curated slice is shorter; `WorkspaceAppDiscovery.swift`, `BundleDocumentTypeReader.swift`, and `EditorRankingPolicy.swift` compute supported extension counts for non-curated candidates while preserving the curated order; `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift`, `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift`, and `Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift` assert both behaviors. |
| 4 | A requested editor can be applied to the full developer-text scope and reported as matched, mismatched, unsupported, or write-failed. | ✓ VERIFIED | `App/Application/GlobalText/GlobalTextSwitchCoordinator.swift` applies writes across all declared `.allText` UTTypes and aggregates `AssociationVerificationResult` values into `GlobalTextSwitchReport`; `Tests/DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests.swift` verifies both type coverage and aggregate counts. |
| 5 | The menu refreshes from system state after apply without showing success, failure, or extension-preview messaging in the dropdown. | ✓ VERIFIED | `MenuBarViewModel.applyEditor(bundleID:)` stores the report and reloads current state, while `MenuBarContentView.swift` renders the app list without any inline feedback row; covered by `testApplyEditorStoresLatestAggregateReportAndTriggersReload()` and `testApplyKeepsLatestReportWithoutPublishingMenuFeedback()`. |
| 6 | The menu exposes a real `Open Rules Window...` action while staying menu-bar-first. | ✓ VERIFIED | `App/Features/MenuBar/MenuBarContentView.swift` keeps the footer action last and opens `rules-window`; `RulesWindowPlaceholderView.swift` provides the placeholder content; automated tests and live UAT confirmed the window opens successfully from the resident utility. |

**Score:** 6/6 truths verified in code and automated tests

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `App/DefaultEditorSwitcherApp.swift` | Resident menu bar shell plus rules-window scene | ✓ EXISTS + SUBSTANTIVE | Defines `MenuBarExtra` and `WindowGroup(..., id: "rules-window")`. |
| `App/Application/GlobalText/GlobalTextStateService.swift` | Global text current-state aggregation | ✓ EXISTS + SUBSTANTIVE | Reads all declared `.allText` UTTypes and summarizes single/mixed/unavailable state. |
| `App/Application/GlobalText/GlobalTextSwitchCoordinator.swift` | Dedicated batch apply coordinator | ✓ EXISTS + SUBSTANTIVE | Applies verified writes across the full developer-text scope and aggregates outcomes. |
| `App/Application/GlobalText/GlobalTextSwitchReport.swift` | Structured aggregate report model | ✓ EXISTS + SUBSTANTIVE | Tracks counts, processed content types, and representative failures. |
| `App/Features/MenuBar/MenuBarContentView.swift` | Summary-first menu UI with footer window action | ✓ EXISTS + SUBSTANTIVE | Renders summary, grouped editor sections, and final footer action in contract order while keeping the dropdown compact. |
| `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` | Candidate support-count derivation for global ordering | ✓ EXISTS + SUBSTANTIVE | Computes supported developer-text extension counts from bundle declarations and passes them into ranking. |
| `App/Features/MenuBar/RulesWindowPlaceholderView.swift` | Placeholder window for advanced rules | ✓ EXISTS + SUBSTANTIVE | Explains that advanced language and custom extension rules arrive in later phases. |
| `Tests/DefaultEditorSwitcherTests/GlobalTextStateServiceTests.swift` | Current-state aggregation coverage | ✓ EXISTS + SUBSTANTIVE | Covers single, mixed, and unavailable states. |
| `Tests/DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests.swift` | Batch apply coverage | ✓ EXISTS + SUBSTANTIVE | Covers declared-type filtering and aggregate result counting. |
| `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift` | Menu load/apply/window exposure coverage | ✓ EXISTS + SUBSTANTIVE | Covers loading, 12-row primary ordering, eligible-app backfill to 12 rows, capped current-row injection, apply reload, and rules-window action exposure. |
| `Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift` | Curated recommended-editor ordering and non-curated global fallback ordering coverage | ✓ EXISTS + SUBSTANTIVE | Covers the global recommended ordering, including `Kiro` immediately after `Cursor`, plus non-curated sorting by supported extension count. |
| `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift` | Bundle metadata parsing and support-count derivation coverage | ✓ EXISTS + SUBSTANTIVE | Covers bundle declaration parsing, capability classification, and non-curated ordering by supported extension count. |

**Artifacts:** 10/10 verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `GlobalTextStateService.swift` | `ContentTypeResolver.swift` | `resolutions(for: .allText)` | ✓ WIRED | Global state reads the full developer-text scope rather than a sample extension. |
| `MenuBarViewModel.swift` | `GlobalTextStateService.swift` | `load()` | ✓ WIRED | Menu loading reads current global state through the application service. |
| `MenuBarViewModel.swift` | `WorkspaceAppDiscovery.swift` | `discoverEditors(for: .plainText, bucket: nil)` | ✓ WIRED | Ranked editor candidates feed the menu sections directly. |
| `GlobalTextSwitchCoordinator.swift` | `LaunchServicesAssociationVerifier.swift` | `verify(requestedBundleID:for:)` | ✓ WIRED | Batch apply delegates per-type verification to the Phase 1 association writer. |
| `MenuBarContentView.swift` | `DefaultEditorSwitcherApp.swift` | `openWindow(id: "rules-window")` | ✓ WIRED | Footer action targets the stable scene id hosted by the app shell. |

**Wiring:** 5/5 connections verified

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| MENU-01: open the app from the macOS menu bar without opening the main window | ✓ SATISFIED | - |
| MENU-02: see the current global text default editor directly in the menu bar UI | ✓ SATISFIED | - |
| MENU-03: switch the global text default editor from the menu bar in one interaction flow | ✓ SATISFIED | - |
| GLOB-01: apply one editor as the default opener for the built-in text-like scope | ✓ SATISFIED | - |
| GLOB-03: verify the result of a global switch and show whether the effective default matches the requested editor | ✓ SATISFIED | - |
| DIST-03: behave as a menu bar utility while still opening the main window for advanced configuration | ✓ SATISFIED | - |

**Coverage:** 6 satisfied

## Human Verification

1. Launch confirmed the resident menu bar item appears without opening a preferences-first window.
2. Live switching confirmed the summary and inline `Current` marker update after the write completes.
3. The dropdown stays focused on app choices only and does not show success, failure, or extension-preview messaging after switching.
4. `Open Rules Window...` opens the placeholder window correctly.
5. The AppKit layout recursion warning no longer appears during menu presentation.

## Gaps Summary

No verification gaps remain. Phase 2 passed code review, automated tests, and human UAT.

## Verification Metadata

**Verification approach:** Goal-backward from the Phase 2 roadmap goal, plan must-haves, and phase validation strategy.
**Must-haves source:** `02-01-PLAN.md`, `02-02-PLAN.md`, `02-03-PLAN.md`, and the Phase 2 success criteria in `ROADMAP.md`.
**Automated checks:** source inspection, `rg` acceptance checks, and `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/GlobalTextStateServiceTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`.
**Human checks required:** 0 remaining
**Total verification time:** 15m

---
*Verified: 2026-03-25T14:54:49Z*
*Verifier: Codex*
