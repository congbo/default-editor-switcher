# Phase 1: Discovery & Association Core - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase defines the product's built-in file taxonomy, editor discovery model, and the verified Launch Services read/write core that later phases depend on. It does not add menu bar UX, advanced rules management, restore UX, or release packaging beyond what is needed to understand and validate the system integration foundation.

</domain>

<decisions>
## Implementation Decisions

### File Scope Baseline
- **D-01:** The built-in "all text files" scope for v1 uses a developer-strict set rather than a broad generic text umbrella.
- **D-02:** Source-code extensions are included in the global text baseline from the start, not held back exclusively for later language buckets.
- **D-03:** Language-specific rules introduced in later phases are an override layer on top of the global text baseline, not a separate parallel scope model.

### Editor Discovery and Ranking
- **D-04:** Editor lists should be organized in two tiers: recommended editors first, then other system-eligible applications.
- **D-05:** Recommended editors should use a hybrid ranking model: a global preferred list for common developer editors, plus lightweight per-language weighting for specific buckets in later phases.
- **D-06:** System-declared eligible applications should still be discoverable even when they are not part of the curated recommended editor list.

### the agent's Discretion
- Partial-support handling strategy for editors that only cover some files in a target scope can be determined during research and planning for this phase.
- Verification granularity after Launch Services writes can be determined during research and planning for this phase, as long as the result is reliable enough to support later restore and UX work.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope
- `.planning/PROJECT.md` — product definition, constraints, user priorities, and locked rule-model decisions
- `.planning/REQUIREMENTS.md` — Phase 1 requirement IDs (`DISC-01`, `DISC-02`, `DISC-03`, `GLOB-02`) and current v1 boundaries
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and plan breakdown anchor
- `.planning/STATE.md` — current blockers and session continuity for the milestone

### Research Context
- `.planning/research/SUMMARY.md` — cross-cutting research conclusions and phase ordering rationale
- `.planning/research/STACK.md` — native macOS stack choices, direct distribution constraints, and framework recommendations
- `.planning/research/ARCHITECTURE.md` — proposed service boundaries and Launch Services integration model
- `.planning/research/PITFALLS.md` — discovery pitfalls, partial-support risk, and verification/recovery concerns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — the repository does not contain product code at this stage.

### Established Patterns
- None yet — this phase should establish the first domain and system-integration patterns for the app.

### Integration Points
- New code will define the initial app structure and system integration boundaries that later UI phases build on.

</code_context>

<specifics>
## Specific Ideas

- The product should feel like `default-browser` in spirit for fast switching, but this phase is explicitly about the capability foundation rather than reproducing UI behavior yet.
- The "all text" concept should stay developer-centered and not drift into a generic all-file-type manager.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-discovery-association-core*
*Context gathered: 2026-03-25*
