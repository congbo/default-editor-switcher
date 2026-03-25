# Phase 4: Release Hardening - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase ships the app as a trustworthy direct-download macOS utility. It covers signing, notarization, install verification, and user-facing failure handling for association writes. It does not add new editor-routing capabilities, language rules, restore UX, or automation features beyond what is needed to make the current product releasable and understandable when something fails.

</domain>

<decisions>
## Implementation Decisions

### Release Packaging
- **D-01:** The release path should target direct distribution with Developer ID signing and notarization, not Mac App Store packaging or sandbox-first compromises.
- **D-02:** Release output should be a reproducible installable artifact that can be validated outside Xcode, with the app archive and notarization steps treated as first-class workflow outputs rather than an informal manual export.

### Failure UX
- **D-03:** Association-write failures should surface as actionable product copy, not raw OSStatus-only diagnostics. The UI should identify the affected scope, whether the failure was partial or full, and what recovery step the user can take next.
- **D-04:** Existing verification statuses such as `mismatched`, `unsupportedTarget`, and `writeFailed` should remain the truth source for release-hardening UX instead of introducing a separate ad hoc error model.

### Release Verification
- **D-05:** Release validation should prove the shipped artifact on a clean-machine-style flow: install the signed artifact, verify Gatekeeper acceptance, launch it outside a debug session, and confirm the core switching path still behaves correctly.
- **D-06:** The release checklist should be scriptable where possible and leave behind concrete evidence for each stage, such as archive/export success, notarization status, and post-install verification results.

### the agent's Discretion
- The exact artifact wrapper (`.dmg` vs `.zip`) can be chosen during planning as long as the result supports notarized direct download and straightforward install verification.
- The exact presentation layer for failure messages can be decided during planning as long as the user sees scope, failure type, and recovery guidance without opening logs first.
- Local helper scripts, release-check command wrappers, and CI hooks can be introduced if they reduce operator error without expanding product scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and Milestone Scope
- `.planning/PROJECT.md` — product boundaries, direct-download distribution constraint, and developer-first UX priorities
- `.planning/REQUIREMENTS.md` — release-facing requirements `DIST-01` and `DIST-02`, plus prior constraints that must remain intact
- `.planning/ROADMAP.md` — Phase 4 goal, success criteria, and planned work breakdown
- `.planning/STATE.md` — current milestone position after Phase 03 completion

### Prior Phase Context
- `.planning/phases/01-discovery-association-core/01-CONTEXT.md` — validated Launch Services foundation and capability-model decisions
- `.planning/phases/02-menu-bar-global-switch/02-CONTEXT.md` — menu-first UX constraints and current global-switch interaction model
- `.planning/phases/03-native-settings-window/03-UAT.md` — latest human verification proving the pre-release product surface is stable before hardening

### Research and Distribution Constraints
- `.planning/research/STACK.md` — recommended direct-distribution toolchain, notarization path, and sandbox avoidance rationale
- `.planning/research/ARCHITECTURE.md` — current service-boundary direction that release hardening should preserve
- `.planning/research/PITFALLS.md` — known reliability and integration risks relevant to shipping

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `App/Infrastructure/LaunchServices/LaunchServicesAssociationVerifier.swift` — already produces verified per-target outcomes that can drive release-safe failure messaging.
- `App/Application/GlobalText/GlobalTextSwitchReport.swift` — already aggregates partial and full failure counts, which should feed any hardened user-facing error summaries.
- `App/Features/Settings/SettingsCopyFormatter.swift` and `App/Resources/Localizable.xcstrings` — provide the current localized copy pipeline that release-facing error text should plug into instead of adding hard-coded strings.
- `DefaultEditorSwitcher.xcodeproj/project.pbxproj` — owns current target/signing configuration and will be the integration point for archive/export readiness.

### Established Patterns
- System integration logic is isolated behind service and infrastructure types, so release hardening should extend those boundaries instead of pushing Launch Services error handling into SwiftUI views.
- Product copy is moving toward localized app-owned strings, so release errors and recovery guidance should follow the same catalog-backed path.
- The app already verifies writes after association changes, so Phase 4 should harden the presentation and release validation around that existing verification loop rather than replacing it.

### Integration Points
- Release tooling will likely connect at the Xcode project and `Tools/` layer, with verification outputs feeding back into planning docs or release checklists.
- User-facing failure handling will connect to the existing global-switch coordinator/view-model path and any later rule-application flows that reuse the same verification results.
- Final release validation should exercise the app from the built artifact, not only the XCTest target, so the plan must account for archive/export/install steps in addition to unit tests.

</code_context>

<specifics>
## Specific Ideas

- Keep the shipped experience aligned with the product's current positioning as a tiny native utility: release hardening should increase trust, not add enterprise-style ceremony to the UI.
- Favor a release workflow that the developer can run repeatedly on their own machine before introducing CI or more automation.

</specifics>

<deferred>
## Deferred Ideas

- App Store compatibility or sandbox-compliant packaging — still out of scope for this product shape.
- Restore snapshots, baseline recovery flows, and richer rule diagnostics — belong to future product phases beyond release hardening.

</deferred>

---

*Phase: 04-release-hardening*
*Context gathered: 2026-03-26*
