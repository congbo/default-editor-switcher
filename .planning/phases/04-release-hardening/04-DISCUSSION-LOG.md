# Phase 4: Release Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26T04:30:36+08:00
**Phase:** 04-release-hardening
**Areas discussed:** release packaging, failure UX, release verification

---

## Release Packaging

| Option | Description | Selected |
|--------|-------------|----------|
| Direct download with Developer ID signing and notarization | Ship a release artifact that can be installed outside the App Store and validated independently of Xcode. | ✓ |
| Debug-build sharing only | Treat local Xcode builds as sufficient for early users and defer real packaging. | |
| App Store-oriented packaging | Optimize for sandbox/App Store constraints first. | |

**User's choice:** `[auto]` Direct download with Developer ID signing and notarization
**Notes:** Chosen because the project constraints already lock distribution to direct download first and Phase 4 exists to make that path shippable.

---

## Failure UX

| Option | Description | Selected |
|--------|-------------|----------|
| Actionable scope-aware errors | Show the affected scope, failure type, and recovery guidance using existing verification outcomes. | ✓ |
| Generic failure copy | Show a simple failure message without scope-specific detail. | |
| Logs-first diagnostics | Keep detailed failure information only in logs or developer tools. | |

**User's choice:** `[auto]` Actionable scope-aware errors
**Notes:** Chosen because `DIST-02` explicitly requires actionable error messaging, and the codebase already has structured verification statuses to support it.

---

## Release Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Clean-machine-style artifact verification | Validate archive/export, notarization, Gatekeeper acceptance, launch, and core app behavior from the shipped artifact. | ✓ |
| Build-machine smoke test only | Confirm the app works only from local dev builds. | |
| Ad hoc manual spot checks | Leave release verification to unstructured manual testing. | |

**User's choice:** `[auto]` Clean-machine-style artifact verification
**Notes:** Chosen because `DIST-01` requires a trustworthy signed/notarized install flow, which cannot be proven from debug-only testing.

---

## the agent's Discretion

- Choose the exact shipped archive wrapper and helper-script shape during planning.
- Decide how release verification evidence is stored as long as the steps are reproducible and reviewable.

## Deferred Ideas

- App Store compatibility and sandbox adaptation
- Restore/recovery product features beyond release-focused failure guidance
