# Phase 3: Language Override Engine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 03-language-override-engine
**Areas discussed:** Override intent model, editing surface, precedence and apply strategy, state and verification model

---

## Override Intent Model

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit persisted overrides keyed by `LanguageBucket` | Stores requested editor intent per built-in language bucket so later global switches can reapply exceptions deterministically. | ✓ |
| Infer intent from current Launch Services handlers | Avoids local state, but user intent becomes ambiguous after mixed writes or manual system changes. | |
| Write-through only with no persisted override model | Simplest short-term path, but it cannot reliably keep language exceptions alive after future global switches. | |

**User's choice:** Explicit persisted overrides keyed by `LanguageBucket`
**Notes:** [auto] Selected the recommended default because `LANG-07` requires language-specific assignments to survive later global text changes.

---

## Editing Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Use the existing Settings/Rules window for built-in language rows | Keeps the menu bar focused on the high-frequency global action while giving Phase 3 a credible place to manage language overrides. | ✓ |
| Add per-language submenus directly to the menu bar | Shortens access, but it overloads the menu-bar flow and erodes the product's menu-first simplicity. | |
| Ship engine-only behavior with no user-facing override editing surface yet | Avoids UI work now, but it fails the requirement that users can assign dedicated editors for each language bucket. | |

**User's choice:** Use the existing Settings/Rules window for built-in language rows
**Notes:** [auto] Selected the recommended default because Phase 2 already established that advanced rule editing belongs in the fuller window path, not in the menu-bar switcher.

---

## Precedence and Apply Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Model precedence as `custom > language > global`, and reapply stored language overrides after every global switch | Keeps the long-term rule engine consistent now and guarantees that global changes do not wipe out saved language exceptions. | ✓ |
| Treat global and language rules as separate write paths with no automatic replay | Simpler orchestration, but bucket-specific defaults can silently disappear after the next global switch. | |
| Rely on last-write-wins behavior across overlapping scopes | Minimal domain logic, but precedence becomes implicit, brittle, and hard to explain or test. | |

**User's choice:** Model precedence as `custom > language > global`, and reapply stored language overrides after every global switch
**Notes:** [auto] Selected the recommended default because deterministic precedence is the point of the phase and aligns with the already-locked product model.

---

## State and Verification Model

| Option | Description | Selected |
|--------|-------------|----------|
| Derive each bucket's state from all declared content types and reuse aggregate verification results | Surfaces mixed or partial outcomes honestly and matches the verified batch-apply pattern already used for global text. | ✓ |
| Use one representative extension per bucket | Faster to implement, but it can report false confidence when other types in the same bucket differ. | |
| Show only the requested target editor and skip verification detail | Simplifies UI, but hides partial failures and weakens product trust. | |

**User's choice:** Derive each bucket's state from all declared content types and reuse aggregate verification results
**Notes:** [auto] Selected the recommended default because Phase 2 already committed to verified aggregate state instead of representative sampling.

---

## the agent's Discretion

- Exact control choice for each language row
- Exact copy and visual treatment for mixed bucket states
- Whether apply is immediate per row or explicit per bucket

## Deferred Ideas

- Custom extension rule editing and conflict visualization — Phase 4
- Broader rules-window shell and navigation — Phase 4
- Snapshot and restore workflows — Phase 5
- Profiles and automation presets — v2 or backlog
