# Phase 5: Milestone Verification Closure - Research

**Researched:** 2026-03-26
**Domain:** milestone verification debt closure, release-requirement rebaselining, and planning-record synchronization
**Confidence:** HIGH

<user_constraints>
## User Constraints (from roadmap and current milestone state)

### Locked Decisions
- Phase 5 must close the blockers recorded in `v1.0-MILESTONE-AUDIT.md` without reopening product implementation scope.
- `DIST-01` may be resolved either by a credentialed signed/notarized install run or by an explicit verified replacement requirement.
- Planning artifacts must match the final verified milestone record before archival.

### the agent's Discretion
- Prefer the rebaseline path if the required external credentials are unavailable.
- Treat missing verification artifacts as a documentation debt problem, not a request to re-run already-passed product behavior manually.

### Deferred Ideas (OUT OF SCOPE)
- Any new product code beyond documentation-only planning sync
- A live notarization run that depends on missing Developer ID credentials

</user_constraints>

<research_summary>
## Summary

Phase 5 is a closure phase, not a feature phase. The evidence gap is narrow and well-bounded:

1. Phase 3 is implemented, validated, and manually tested, but it never received the canonical `03-VERIFICATION.md` report that the milestone audit expects.
2. Phase 4 proved the release pipeline, preview packaging, recovery UX, and installed-build verification scripts, but it could not prove the original `DIST-01` wording because there was no credentialed Developer ID / notarization run in-session.
3. The planning layer still reflects an earlier point in time, so `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` disagree with the real milestone state.

The least risky path is to rebaseline `DIST-01` to a replacement requirement that the repository actually proves today: the team can produce and validate a direct-download preview release candidate outside the Mac App Store, and the repo documents the exact credentialed Developer ID path needed for GA notarization later. That is already supported by `04-HUMAN-UAT.md`, the preview build/release scripts, and the Phase 4 verification artifacts. It avoids making a false claim about notarized GA install proof while still preserving a concrete distribution contract for v1.0.

**Primary recommendation:** split Phase 5 into three small plans matching the roadmap: reconstruct Phase 3 verification, rebaseline and close `DIST-01`, then synchronize roadmap/state/requirements plus the milestone audit.
</research_summary>

<architecture_patterns>
## Patterns

### Pattern 1: Canonical verification reports are phase-level closure artifacts
Use a `*-VERIFICATION.md` report even when the underlying evidence already exists in validation/UAT docs. The verification report is the milestone-level source of truth for phase completion.

### Pattern 2: Rebaseline requirements only when evidence is explicit
If the original wording cannot be proven, replace it with a narrower requirement that is fully supported by repo-owned evidence and clearly document the change.

### Pattern 3: Audit last
Update verification and requirements first, then write the milestone audit from the synchronized record. Otherwise the audit will keep re-reporting stale gaps.

</architecture_patterns>

<implementation_notes>
## Implementation Notes

- Phase 3 verification should cover `PROD-02` and `DIST-03`, because those are the roadmap-bound requirements for the settings-window phase.
- The replacement `DIST-01` wording should explicitly reference the verified preview/direct-download release contract and the documented notarization path for later GA shipping.
- Move unimplemented language overrides, custom extension rules, and restore features out of v1 scope so the archived requirements record matches what actually shipped in v1.0.
- The final milestone audit should mark the milestone `passed`; any remaining note about Phase 1 Nyquist partial coverage can stay as non-blocking historical debt.

</implementation_notes>

## Validation Architecture

- Verification is documentation-first: `rg`, file presence, frontmatter consistency, and source cross-reference checks are sufficient.
- No new manual or automated product test execution is required beyond existing Phase 3 and Phase 4 evidence.
- Phase 5 passes when `03-VERIFICATION.md`, `04-VERIFICATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, and `v1.0-MILESTONE-AUDIT.md` all agree on the closed milestone record.
