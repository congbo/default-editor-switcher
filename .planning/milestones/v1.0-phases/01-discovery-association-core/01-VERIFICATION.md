---
phase: 01-discovery-association-core
verified: 2026-03-25T13:20:49Z
status: passed
score: 4/4 must-haves verified
---

# Phase 1: Discovery & Association Core Verification Report

**Phase Goal:** Build the product's file-type taxonomy, editor discovery model, and the verified Launch Services mutation/readback core.
**Verified:** 2026-03-25T13:20:49Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App can resolve the built-in text-like and language bucket scopes into concrete extensions and content types. | ✓ VERIFIED | `App/Domain/Types/FileScope.swift`, `App/Domain/Types/LanguageBucket.swift`, and `App/Domain/Types/ContentTypeResolver.swift` define the scope model, bucket extensions, UTType resolution, and text/source-code conformance flags. |
| 2 | App can list eligible editors with icon, name, bundle identifier, and capability metadata for a representative target scope. | ✓ VERIFIED | `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` maps `NSWorkspace.shared.urlsForApplications(toOpen:)` into `EditorCandidate` values with display name, bundle ID, icon lookup path, source tier, and capability classification; deterministic coverage exists in `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift`. |
| 3 | A prototype association writer can update and re-read default handlers for representative text/source-code types. | ✓ VERIFIED | Local `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'` completed with `** TEST SUCCEEDED **`. Outside the sandbox, `AssociationProbe --extension md --bundle-id dev.zed.Zed` returned `requested=dev.zed.Zed`, `effective=dev.zed.Zed`, `status=matched`, and `AssociationProbe --extension txt --bundle-id com.sublimetext.4` returned `requested=com.sublimetext.4`, `effective=com.sublimetext.4`, `status=matched`; the original handlers were then restored to `abnerworks.Typora` for markdown and `com.apple.TextEdit` for plain text. |
| 4 | Unsupported or partially supported editors are surfaced clearly enough to avoid misleading switch actions. | ✓ VERIFIED | `App/Domain/Editors/EditorCandidate.swift` models `.full`, `.partial`, and `.unverified`; `WorkspaceAppDiscovery.capability(...)` derives those states; `App/Domain/Associations/AssociationVerificationResult.swift` preserves `matched`, `mismatched`, `unsupportedTarget`, and `writeFailed` outcomes; tests cover the unsupported/write-failed paths. |

**Score:** 4/4 truths verified

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
| DISC-03: only offer validated editors or clearly warn on partial support | ✓ SATISFIED | Real-machine `AssociationProbe` smoke runs succeeded for representative markdown and plain-text handlers, with readback matching the requested bundle IDs and the original handlers restored afterward. |
| GLOB-02: built-in text-like file scope includes the developer-oriented baseline | ✓ SATISFIED | - |

**Coverage:** 4/4 requirements satisfied

## Anti-Patterns Found

None observed in the implemented phase artifacts.

## Human Verification Completed

### 1. Association Probe Smoke Run
**Executed:** 2026-03-25 on the local machine outside the Codex sandbox.
**Result:** `md` switched to `dev.zed.Zed` and read back as matched, then was restored to `abnerworks.Typora`; `txt` switched to `com.sublimetext.4` and read back as matched, then was restored to `com.apple.TextEdit`.
**Why it mattered:** This confirmed the real Launch Services mutation/readback path, not only the mock-backed verifier and probe build wiring.

## Gaps Summary

**No implementation gaps found.** Phase 1 no longer has any outstanding verification blockers.

## Verification Metadata

**Verification approach:** Goal-backward from the Phase 1 roadmap goal and plan must-haves
**Must-haves source:** `01-01-PLAN.md`, `01-02-PLAN.md`, `01-03-PLAN.md`, and Phase 1 success criteria in `ROADMAP.md`
**Automated checks:** source inspection, `rg` acceptance checks, `swiftc` typechecks, local `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`, and `xcodebuild build -scheme AssociationProbe -derivedDataPath .build/DerivedData`
**Environment note:** Codex could not re-run `xcodebuild test` inside its sandbox because of a `testmanagerd` restriction, but the same command was executed successfully on the local machine and the machine-level `AssociationProbe` smoke runs also passed outside the sandbox.
**Human checks required:** 0
**Total verification time:** 24m

---
*Verified: 2026-03-25T13:20:49Z*
*Verifier: Codex*
