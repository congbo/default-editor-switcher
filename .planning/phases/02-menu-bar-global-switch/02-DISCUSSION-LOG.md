# Phase 2: Menu Bar Global Switch - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-25T13:26:54Z
**Phase:** 02-menu-bar-global-switch
**Areas discussed:** Menu Bar Shell, Current-State Presentation, Editor List and Apply Flow, Feedback and Advanced Access

---

## Menu Bar Shell

| Option | Description | Selected |
|--------|-------------|----------|
| Native `MenuBarExtra` | Standard macOS utility shape, aligns with research and keeps the high-frequency path minimal | ✓ |
| Dock-first app window | Users open a window before switching, which slows the core action | |
| Custom detached popover shell | More bespoke UI freedom, but adds complexity before the product proves its menu-bar core | |

**User's choice:** `[auto] Native MenuBarExtra`
**Notes:** Auto fallback selected the recommended default because Phase 2 explicitly exists to deliver the menu-bar-first value and the research stack already recommends `MenuBarExtra`.

---

## Current-State Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Summary row + active checkmark | Show the current global editor in a compact summary and also mark it in the editor list | ✓ |
| Checkmark only | Saves space, but forces users to scan the action list to infer current state | |
| Icon-only status | Minimizes text, but is too ambiguous for a utility whose main trust signal is current state clarity | |

**User's choice:** `[auto] Summary row + active checkmark`
**Notes:** Auto fallback selected the recommended default because `MENU-02` requires visible current state and the menu should not rely on subtle icon states alone.

---

## Editor List and Apply Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Full-support one-click list, ranked with warnings separated | Keep fully eligible editors as immediate actions, recommended editors first, and visually separate partial/unverified options | ✓ |
| Show every discovered app equally | Simple to implement, but hides capability differences and weakens trust | |
| Hide anything not recommended | Keeps the menu short, but violates the product rule that system-eligible apps should remain discoverable | |

**User's choice:** `[auto] Full-support one-click list, ranked with warnings separated`
**Notes:** Auto fallback selected the recommended default because it preserves the one-click switch promise while carrying forward Phase 1's validated-vs-partial discovery model.

---

## Feedback and Advanced Access

| Option | Description | Selected |
|--------|-------------|----------|
| Inline feedback + bottom "Open Main Window" entry | Report success/failure in the menu and keep a persistent path to the fuller app experience | ✓ |
| Modal alert after every apply | Explicit, but too heavy for the primary high-frequency action | |
| Silent apply, no advanced entry | Fast, but provides weak trust signals and fails `DIST-03`'s dual-entry requirement | |

**User's choice:** `[auto] Inline feedback + bottom entry`
**Notes:** Auto fallback selected the recommended default because the menu must remain self-sufficient for Phase 2 while still opening the fuller app shell on demand.

---

## the agent's Discretion

- Exact copy for section headers and status text
- Menu icon choice and row spacing
- Refresh timing details after menu open and after apply

## Deferred Ideas

- Language-specific rules UI and precedence explanations belong to later phases
- Snapshot and restore controls belong to the recovery phase
