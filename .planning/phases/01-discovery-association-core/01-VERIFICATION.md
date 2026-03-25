---
phase: 01-discovery-association-core
verified: 2026-03-25T12:14:05Z
status: human_needed
score: 3/4 must-haves verified
---

# Phase 1: Discovery & Association Core Verification Report

**Phase Goal:** Build the product's file-type taxonomy, editor discovery model, and the verified Launch Services mutation/readback core.
**Verified:** 2026-03-25T12:14:05Z
**Status:** human_needed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App can resolve the built-in text-like and language bucket scopes into concrete extensions and content types. | ✓ VERIFIED | `App/Domain/Types/FileScope.swift`, `App/Domain/Types/LanguageBucket.swift`, and `App/Domain/Types/ContentTypeResolver.swift` define the scope model, bucket extensions, UTType resolution, and text/source-code conformance flags. |
| 2 | App can list eligible editors with icon, name, bundle identifier, and capability metadata for a representative target scope. | ✓ VERIFIED | `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` maps `NSWorkspace.shared.urlsForApplications(toOpen:)` into `EditorCandidate` values with display name, bundle ID, icon lookup path, source tier, and capability classification; deterministic coverage exists in `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift`. |
| 3 | A prototype association writer can update and re-read default handlers for representative text/source-code types. | ? NEEDS HUMAN | `App/Infrastructure/LaunchServices/LaunchServicesClient.swift`, `App/Infrastructure/LaunchServices/LaunchServicesAssociationVerifier.swift`, and `Tools/AssociationProbe/main.swift` implement the read/write/readback path, but the required `xcodebuild` build/test and real-machine smoke run could not execute without a full Xcode.app installation. |
| 4 | Unsupported or partially supported editors are surfaced clearly enough to avoid misleading switch actions. | ✓ VERIFIED | `App/Domain/Editors/EditorCandidate.swift` models `.full`, `.partial`, and `.unverified`; `WorkspaceAppDiscovery.capability(...)` derives those states; `App/Domain/Associations/AssociationVerificationResult.swift` preserves `matched`, `mismatched`, `unsupportedTarget`, and `writeFailed` outcomes; tests cover the unsupported/write-failed paths. |

**Score:** 3/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `App/Domain/Types/ContentTypeResolver.swift` | Source-of-truth developer-text catalog and UTType resolver | ✓ EXISTS + SUBSTANTIVE | Encodes the developer-strict extension baseline and UTType-backed resolution helpers. |
| `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` | System-backed editor discovery with metadata and capability classification | ✓ EXISTS + SUBSTANTIVE | Uses `NSWorkspace` plus bundle inspection and ranking policy to create editor candidates. |
| `App/Infrastructure/LaunchServices/LaunchServicesClient.swift` | Launch Services read/write bridge | ✓ EXISTS + SUBSTANTIVE | Wraps `LSCopyDefaultRoleHandlerForContentType`, `LSCopyAllRoleHandlersForContentType`, and `LSSetDefaultRoleHandlerForContentType`. |
| `Tools/AssociationProbe/main.swift` | Smoke-probe entry point for real-machine validation | ✓ EXISTS + SUBSTANTIVE | Parses `--extension`, `--bundle-id`, `--restore-bundle-id` and prints `requested=`, `effective=`, `status=`. |
| `Tests/DefaultEditorSwitcherTests/FileScopeCatalogTests.swift` | Taxonomy regression coverage | ✓ EXISTS + SUBSTANTIVE | Covers baseline extensions, markdown/web buckets, and normalization. |
| `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift` | Discovery metadata and capability coverage | ✓ EXISTS + SUBSTANTIVE | Uses fixture document-type dictionaries to test metadata parsing and capability states. |
| `Tests/DefaultEditorSwitcherTests/LaunchServicesClientTests.swift` | Association outcome coverage | ✓ EXISTS + SUBSTANTIVE | Covers matched, mismatched, unsupportedTarget, and writeFailed outcomes with a mock client. |

**Artifacts:** 7/7 verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `FileScope.swift` | `ContentTypeResolver.swift` | `extensions(for:)` / `resolutions(for:)` | ✓ WIRED | File scopes feed the resolver's extension and resolution APIs. |
| `WorkspaceAppDiscovery.swift` | `KnownEditors.swift` | `KnownEditors.isRecommended(bundleID:)` | ✓ WIRED | Discovery marks candidates as recommended vs. system-eligible before ranking. |
| `WorkspaceAppDiscovery.swift` | `EditorCandidate.swift` | `EditorCandidate(...)` initializer | ✓ WIRED | Discovery emits bundle ID, display name, icon path, source, and capability into the shared candidate model. |
| `LaunchServicesAssociationVerifier.swift` | `LaunchServicesClient.swift` | read/write/readback flow | ✓ WIRED | Verifier reads current handler, checks eligibility, performs the write, and reads back the effective handler. |
| `Tools/AssociationProbe/main.swift` | `LaunchServicesAssociationVerifier.swift` | `verify(requestedBundleID:for:)` | ✓ WIRED | The probe exercises the same verifier path used by the app layer. |

**Wiring:** 5/5 connections verified

## Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| DISC-01: discover installed editors from preferred and system-declared handlers | ✓ SATISFIED | - |
| DISC-02: show app icon, display name, and bundle identifier for discovered editors | ✓ SATISFIED | - |
| DISC-03: only offer validated editors or clearly warn on partial support | ? NEEDS HUMAN | Code and tests model the distinction, but the real-machine Launch Services smoke path has not been executed in a full Xcode environment. |
| GLOB-02: built-in text-like file scope includes the developer-oriented baseline | ✓ SATISFIED | - |

**Coverage:** 3/4 requirements satisfied, 1/4 needs human verification

## Anti-Patterns Found

None observed in the implemented phase artifacts. The blocker is environmental verification, not placeholder or stub code.

## Human Verification Required

### 1. Full Xcode Build/Test Pass
**Test:** Install or select a full `Xcode.app`, then run:
`xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`
and
`xcodebuild build -scheme AssociationProbe -destination 'platform=macOS'`
**Expected:** The app target, test target, and probe target build successfully, and the phase-1 test suites pass under Xcode.
**Why human:** This workspace only has `/Library/Developer/CommandLineTools`; `xcodebuild` is unavailable without a full Xcode installation.

### 2. Association Probe Smoke Run
**Test:** Use `AssociationProbe` against a representative text extension such as `txt` or `md`, providing a known editor bundle ID and a `--restore-bundle-id` for cleanup.
**Expected:** Output shows the requested bundle ID, an effective bundle ID matching the request after the write, `status=matched`, and the original handler is restored successfully.
**Why human:** This requires mutating real Launch Services preferences on the machine and validating the actual readback path, which was not safe or possible in the CLT-only environment.

## Gaps Summary

**No implementation gaps found.** The remaining work is human verification of the Xcode-backed build/test path and the real-machine association smoke run.

## Verification Metadata

**Verification approach:** Goal-backward from the Phase 1 roadmap goal and plan must-haves
**Must-haves source:** `01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md`, and Phase 1 success criteria in `ROADMAP.md`
**Automated checks:** source inspection, `rg` acceptance checks, `swiftc` typechecks, deterministic XCTest source coverage review
**Human checks required:** 2
**Total verification time:** 14m

---
*Verified: 2026-03-25T12:14:05Z*
*Verifier: Codex*
