# Phase 2: Menu Bar Global Switch - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the menu bar utility flow for quickly switching the product's built-in global text scope to a selected editor, showing the current global default directly in the menu bar UI, and exposing an entry point into the app's fuller window experience. It does not add language-specific overrides, custom extension editing, snapshots/restore, or release hardening beyond what is needed to support the menu bar switch flow.

</domain>

<decisions>
## Implementation Decisions

### Menu Bar Shell
- **D-01:** The primary Phase 2 entry point should be a native SwiftUI `MenuBarExtra`, not a dock-first window flow or a custom detached popover shell.
- **D-02:** The menu bar flow should stay menu-first and self-sufficient for the high-frequency action: opening the menu should immediately reveal current state and switch targets without requiring the main window.

### Current-State Presentation
- **D-03:** The menu content should lead with a compact current-state summary for the global text default, not force the user to infer state only from iconography.
- **D-04:** The currently effective global editor should also be marked inline inside the selectable editor list so the active target is obvious at a glance.

### Editor List and Apply Flow
- **D-05:** The switcher list should surface fully eligible editors as immediate one-click actions, preserving the product promise that the common path finishes in a single short interaction.
- **D-06:** Recommended editors should appear before other system-eligible editors, and non-curated apps in the global menu should default to descending order by how many developer-text extensions they declare support for.
- **D-07:** Partially supported or unverified editors should not masquerade as primary switch actions; they should be visibly separated or explained so the menu stays fast without hiding capability caveats.
- **D-10:** The top-level menu should expose up to 12 primary app choices before falling back to overflow, keeping recommended editors first and backfilling with other fully eligible apps when the curated list is shorter; the curated global order should keep `Kiro` immediately after `Cursor`.

### Feedback and Advanced Access
- **D-08:** After a global switch attempt, the menu should refresh the visible current-state summary without forcing the main window to open or adding extra inline feedback rows.
- **D-09:** The menu should include a persistent bottom-level entry point into the app's fuller window experience so the product can remain a menu bar utility while still giving users a path to advanced configuration later.
- **D-11:** The dropdown should omit extension previews and partial-failure messaging entirely so the top-level app list stays dense and stable.

### the agent's Discretion
- Exact menu copy, iconography, and section headers can be decided during planning as long as the primary switch flow remains one interaction and the current global editor is legible.
- Whether the menu refreshes state eagerly on open, after each apply, or both can be chosen during planning as long as stale state is minimized.
- The exact presentation for partial or unverified editors can be decided during planning as long as unsupported options are clearly non-primary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope and Requirements
- `.planning/PROJECT.md` — product promise, menu-bar-first UX constraint, dual-entry architecture, and developer-first positioning
- `.planning/REQUIREMENTS.md` — Phase 2 requirements `MENU-01`, `MENU-02`, `MENU-03`, `GLOB-01`, `GLOB-03`, and `DIST-03`
- `.planning/ROADMAP.md` — Phase 2 goal, success criteria, and plan breakdown
- `.planning/STATE.md` — current project position and session continuity

### Prior Phase Decisions
- `.planning/phases/01-discovery-association-core/01-CONTEXT.md` — locked decisions for developer-text scope, editor ranking tiers, and validated-vs-partial capability handling
- `.planning/phases/01-discovery-association-core/01-VERIFICATION.md` — verified Launch Services mutation/readback foundation that Phase 2 should build on

### Research and Architecture
- `.planning/research/SUMMARY.md` — roadmap rationale that Phase 2 should deliver the core menu bar value before heavier configuration UI
- `.planning/research/STACK.md` — recommended `MenuBarExtra` app shell and Apple-native stack choices
- `.planning/research/ARCHITECTURE.md` — menu bar scene role, thin-SwiftUI/fat-services pattern, and service-layer boundaries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` — already discovers and ranks editor candidates for a content type, so Phase 2 can build menu rows on top of existing discovery instead of re-scanning bundles in the UI.
- `App/Domain/Editors/EditorCandidate.swift` — already models recommended vs system-eligible source and capability states, which should map directly to menu list grouping and warning treatment.
- `App/Infrastructure/LaunchServices/LaunchServicesAssociationVerifier.swift` — already performs requested-vs-effective verification, which should drive menu feedback after a switch action.
- `App/Infrastructure/LaunchServices/LaunchServicesClient.swift` — already exposes current handler lookup and handler mutation primitives for the menu bar flow.
- `App/Domain/Types/ContentTypeResolver.swift` and `App/Domain/Types/FileScope.swift` — already define the built-in developer-text scope that the global switch action needs to expand across.

### Established Patterns
- Current code follows a domain-and-infrastructure split, so Phase 2 should add view models or coordination services rather than embedding discovery and Launch Services logic directly in SwiftUI views.
- Verification outcomes are already explicit (`matched`, `mismatched`, `unsupportedTarget`, `writeFailed`), so the menu UI should present those result states rather than collapsing them into a generic success/failure boolean.
- The app shell is still minimal in `App/DefaultEditorSwitcherApp.swift`, so Phase 2 can introduce the first real scene architecture without refactoring existing UI complexity.

### Integration Points
- `App/DefaultEditorSwitcherApp.swift` is the entry point that should evolve into the menu bar utility shell and expose the future main-window path.
- Phase 2 will need a new application-facing coordinator that expands the global text scope, calls the verifier/writer, and returns UI-friendly aggregate results to the menu bar scene.
- The ranked candidate output from `WorkspaceAppDiscovery` should feed the menu's editor sections directly, avoiding duplicate sorting logic in the UI.

</code_context>

<specifics>
## Specific Ideas

- Carry forward the `default-browser` spirit explicitly: current target should be obvious, switching should feel instant, and the common path should not detour through a preferences window.
- The menu should feel like a trustworthy system utility rather than a generic app launcher: status first, action list second, advanced entry point last.
- Keep the Phase 2 main-window hook lightweight; this phase only needs a credible path into the fuller app, not the final rules-management experience from later phases.

</specifics>

<deferred>
## Deferred Ideas

- Language-specific override editing and precedence previews — Phase 3 and Phase 4
- Custom extension CRUD and conflict explanation — Phase 4
- Snapshots, restore actions, and baseline recovery UX — Phase 5
- Release hardening and notarization-facing failure UX — Phase 6

</deferred>

---

*Phase: 02-menu-bar-global-switch*
*Context gathered: 2026-03-25*
