# Phase 1: Discovery & Association Core - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25
**Phase:** 1-discovery-association-core
**Areas discussed:** File Scope Baseline, Editor Discovery and Ranking

---

## File Scope Baseline

### Question 1: Built-in all-text scope breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Developer-strict set | Covers code, markup, config, scripts, logs, and other developer-centric text files | ✓ |
| Developer-expanded set | Developer-strict set plus broader text/data/document-adjacent types | |
| Ultra-wide text set | Include nearly any system-recognized text-like file | |

**User's choice:** Developer-strict set
**Notes:** v1 should keep the scope tight and developer-first rather than acting like a general text-file manager.

### Question 2: Whether language-bucket extensions belong to the global text baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Include them in the global baseline | Source-code extensions participate in the global text switch, with later language overrides taking precedence | ✓ |
| Keep them separate from the global baseline | Source-code extensions belong only to language-specific buckets | |
| Partial inclusion | Include only a selected subset such as Markdown or config-like types | |

**User's choice:** Include them in the global baseline
**Notes:** The user wants a natural model where global switching affects source files too, and later language-specific rules simply override the global rule.

---

## Editor Discovery and Ranking

### Question 1: Top-level editor list organization

| Option | Description | Selected |
|--------|-------------|----------|
| Recommended first, other eligible apps second | Curated developer editors appear first, followed by system-eligible apps | ✓ |
| Pure system order | Show all eligible apps in the order returned by the system | |
| Curated list only | Show only built-in known editors and hide other apps unless explicitly requested | |

**User's choice:** Recommended first, other eligible apps second
**Notes:** The user wants the product to feel curated for developers without losing access to other apps declared by the system.

### Question 2: Recommended editor ranking logic

| Option | Description | Selected |
|--------|-------------|----------|
| One global preferred list | Use the same preferred ranking across all scopes | |
| Fully scope-specific ranking | Recommendation order changes heavily per language or target scope | |
| Hybrid ranking | Start with a global preferred list and add lightweight per-language weighting where useful | ✓ |

**User's choice:** Hybrid ranking
**Notes:** The user wants a globally recognizable list with small language-aware adjustments rather than a heavy recommendation engine.

---

## the agent's Discretion

- Partial-support handling for editors that only claim some target file types
- Verification granularity for Launch Services write/readback checks

## Deferred Ideas

None.
