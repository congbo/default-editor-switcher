# Phase 3: Language Override Engine - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the built-in language override engine for Python, Web, Go, Java, Rust, and Markdown, plus enough product surface for users to assign and inspect those built-in overrides. The scope is the deterministic precedence layer that makes language-specific editors win over the global text rule and keeps those exceptions intact after later global switches. It does not add custom extension rules, full rules-window navigation, snapshot/restore flows, or release hardening.

</domain>

<decisions>
## Implementation Decisions

### Override Intent and Persistence
- **D-01:** Phase 3 should introduce an explicit persisted language-override intent model keyed by `LanguageBucket`, storing the requested editor bundle identifier for each built-in bucket instead of inferring user intent from the current Launch Services state.
- **D-02:** Persisted language overrides should use lightweight local app state suitable for v1, with `UserDefaults`-backed storage acceptable, so later global text switches can automatically reapply bucket exceptions.
- **D-03:** The built-in bucket set stays fixed to the requirement-backed buckets already present in code: `python`, `web`, `go`, `java`, `rust`, and `markdown`. Phase 3 does not expand into arbitrary user-defined scopes.

### Editing Surface
- **D-04:** Language override editing should live in the existing Settings/Rules window path, keeping the menu bar focused on the one-click global switch rather than adding per-language controls to the menu itself.
- **D-05:** The Phase 3 window should stay narrowly scoped to built-in language rows that show current/effective editor state and let the user assign a preferred editor. Custom extension CRUD, multi-pane navigation, and broader rules-management chrome stay deferred to Phase 4.
- **D-06:** The Settings window layout should take structural inspiration from the provided `Default Browser Settings` reference image, but only as a layout reference. Phase 3 should favor native macOS controls and patterns over reproducing that app's bespoke visual skin.
- **D-07:** Each built-in language row should use a native right-side `Picker` control rather than a custom floating chooser, inline action list, or drill-in detail page.
- **D-08:** The window should include concise secondary helper text beneath setting groups or rows so precedence and behavior are explained in-context, similar to the reference layout's explanatory copy rhythm.

### Precedence and Apply Flow
- **D-09:** The precedence model should be implemented now as `custom extension > language override > global text`, even though the custom-extension layer is not user-editable until Phase 4.
- **D-10:** Any operation that changes the global text editor must immediately reapply all stored language overrides afterward so `LANG-07` remains true and a global switch never erases existing per-language exceptions.
- **D-11:** Applying a language override should touch only the content types and extensions that belong to that bucket, leaving the global text association as the fallback for the rest of the developer-text scope.

### State and Verification
- **D-12:** Each language bucket should have an aggregated current/effective state derived from all declared content types in that bucket, not from a single representative extension.
- **D-13:** Language override apply results should reuse the verified aggregate-report pattern from Phases 1 and 2, surfacing matched, mismatched, unsupported-target, and write-failed outcomes per bucket so mixed or partial states remain explainable.
- **D-14:** Bucket editor discovery should reuse the Phase 1 ranking model with bucket-specific weights so the UI can recommend language-appropriate editors without inventing a separate catalog or sorting system.

### the agent's Discretion
- Exact wording of helper copy and section headers can be decided during planning as long as precedence and behavior remain legible.
- Exact visual finish, including whether the window is plain native, subtly tinted, or lightly translucent, can be decided during planning as long as layout follows the reference direction and controls remain native-first.
- Whether bucket edits apply immediately per row or through a per-bucket confirmation can be decided during planning, provided persisted intent and verification outcomes stay deterministic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope and Requirements
- `.planning/PROJECT.md` — product promise, developer-first constraints, and the locked rule-model principle that language rules override the global text rule
- `.planning/REQUIREMENTS.md` — Phase 3 requirements `LANG-01` through `LANG-07`, plus adjacent boundaries for Phase 4 and Phase 5
- `.planning/ROADMAP.md` — Phase 3 goal, success criteria, and plan breakdown
- `.planning/STATE.md` — current milestone position and session continuity

### Prior Phase Decisions
- `.planning/phases/01-discovery-association-core/01-CONTEXT.md` — built-in developer-text scope, editor ranking tiers, and the decision that language rules are an override layer rather than a parallel model
- `.planning/phases/01-discovery-association-core/01-VERIFICATION.md` — verified Launch Services mutation/readback behaviors the override engine must continue to respect
- `.planning/phases/02-menu-bar-global-switch/02-CONTEXT.md` — locked menu-bar-first UX boundary and the decision that advanced rule editing belongs in the fuller window path
- `.planning/phases/02-menu-bar-global-switch/02-VERIFICATION.md` — validated aggregate apply/readback behavior for batch association updates that Phase 3 should mirror for language buckets

### Research and Architecture
- `.planning/research/SUMMARY.md` — roadmap rationale for implementing the language override engine immediately after the menu-bar quick switch
- `.planning/research/STACK.md` — Apple-native stack guidance and the v1 recommendation for lightweight local persistence
- `.planning/research/ARCHITECTURE.md` — rule-engine boundary, precedence model, and the recommendation to keep SwiftUI thin and services authoritative

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `App/Domain/Types/LanguageBucket.swift` — already defines the six built-in language buckets and their extension sets; Phase 3 should build state, persistence, and apply flows on top of this enum rather than redefining bucket membership elsewhere.
- `App/Domain/Types/FileScope.swift` and `App/Domain/Types/ContentTypeResolver.swift` — existing scope and UTType resolution APIs already support `.language(bucket)` lookups and should remain the only place bucket extensions are normalized.
- `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift` and `App/Domain/Editors/EditorRankingPolicy.swift` — already discover eligible editors for a content type and apply bucket-aware ranking weights, which is the right basis for language-specific editor pickers.
- `App/Application/GlobalText/GlobalTextStateService.swift` and `App/Application/GlobalText/GlobalTextSwitchCoordinator.swift` — establish the aggregate state and verified batch-apply pattern that the language engine should mirror instead of bypassing.
- `App/Features/MenuBar/RulesWindowPlaceholderView.swift` and `App/DefaultEditorSwitcherApp.swift` — already provide the window entry point that Phase 3 can replace with a focused built-in override view without redesigning the app shell.

### Established Patterns
- The codebase already separates domain models, infrastructure wrappers, and view models; precedence calculation, persistence, and apply orchestration should stay out of SwiftUI views.
- Existing association mutations are verified per content type and summarized into aggregate reports; Phase 3 should extend that pattern instead of introducing fire-and-forget writes.
- Recommended-editor ordering already supports per-bucket weighting, so the language override UI should reuse the current ranking policy rather than hard-coding editor preferences in the view layer.

### Integration Points
- Phase 3 needs a new rules or override application layer that composes persisted language intents with the existing Launch Services verification flow.
- The Settings window should replace `RulesWindowPlaceholderView` with a built-in language override view model and one row per `LanguageBucket`.
- Global text actions in the menu-bar flow will need to honor persisted language overrides when computing final effective bindings, even though the menu UI itself should remain global-only.
- The window UI should be organized as grouped settings sections with native pickers and secondary explanatory text, not as a custom browser-style selector surface.

</code_context>

<specifics>
## Specific Ideas

- Keep the `default-browser` spirit intact: the menu bar remains the fast global action, while language exceptions live in the fuller window.
- Treat Markdown as a first-class language bucket even though `.md` and `.mdx` also belong to the global text set, because that overlap is the clearest user-facing proof that precedence is working.
- The language override surface should feel like a deterministic rule list, not a loose preferences panel.
- Visual reference from discussion: follow the layout rhythm of the provided `Default Browser Settings` screenshot, but do not clone its styling; prefer native macOS components and spacing.

</specifics>

<deferred>
## Deferred Ideas

- Custom extension rule editing, conflict explanation, and the user-facing `custom > language > global` visualization — Phase 4
- Broader rules-window navigation, richer previews, and larger rules-management chrome — Phase 4
- Snapshots, restore actions, and baseline recovery UX — Phase 5
- Import/export, named profiles, and automation-facing rule presets — v2 or backlog

</deferred>

---

*Phase: 03-language-override-engine*
*Context gathered: 2026-03-26*
