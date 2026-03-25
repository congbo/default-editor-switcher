# Phase 2: Menu Bar Global Switch - Research

**Researched:** 2026-03-25
**Domain:** native macOS menu bar flow for global developer-text editor switching
**Confidence:** MEDIUM-HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- The Phase 2 entry point is a native SwiftUI `MenuBarExtra`, not a dock-first window flow or a custom detached popover.
- Opening the menu must immediately reveal current global state and switch targets without making the user enter a separate window.
- The menu leads with a compact current-state summary and also marks the active editor inline inside the selectable editor list.
- Fully eligible recommended editors remain one-click primary actions; partially supported or unverified editors stay visible but clearly non-primary.
- Success or failure feedback must stay inside the menu flow, and the menu must also expose a persistent entry point into the fuller app window.

### the agent's Discretion
- The exact view-model layering, scene IDs, and menu section titles can be chosen as long as the menu stays native and quick.
- Current-state refresh can happen on menu open, after apply, or both, provided stale state is minimized.
- The feedback model can aggregate per-type verification results as long as the UI still shows why a switch only partially succeeded.

### Deferred Ideas (OUT OF SCOPE)
- Language override editing and precedence previews
- Custom extension CRUD
- Snapshot restore UX
- Release hardening beyond keeping the app resident and opening a future rules window

</user_constraints>

<research_summary>
## Summary

Phase 2 should stay narrow: build a native `MenuBarExtra` shell around the already-verified Phase 1 discovery and Launch Services primitives, then add a small application-facing coordinator layer that translates the raw per-content-type verification results into menu-friendly current state, grouped editor rows, and post-apply feedback. The existing repository already has the hard parts for discovery and per-type verification: `WorkspaceAppDiscovery` can produce ranked `EditorCandidate` values for a `UTType`, `ContentTypeResolver` already defines the developer-text scope, and `LaunchServicesAssociationVerifier` already distinguishes `matched`, `mismatched`, `unsupportedTarget`, and `writeFailed`. The missing work is orchestration, aggregation, and menu-scene presentation.

The main design risk is not visual styling but state ambiguity. A global text scope spans many content types, so the menu cannot assume there is a single current handler unless it explicitly reads the resolved scope and checks whether all eligible text types converge on one bundle identifier. Phase 2 therefore needs a read-side service that summarizes the current global text state as one of: unified editor, mixed editors, or unavailable. That same service should feed the summary row at menu open and after writes.

The recommended implementation split mirrors the roadmap plans. First, add a resident app shell plus a menu feature model that can load the current state and candidate lists without mutating anything. Second, add a global-switch coordinator that expands `.allText`, applies the requested bundle ID to every declared type, and returns an aggregate report with counts and representative failures. Third, wire menu feedback, explicit refresh, and the main-window entry point so the app behaves like a trustworthy utility rather than a thin wrapper around blind writes.

**Primary recommendation:** keep the menu UI declarative and native, and concentrate all multi-type read/write logic in a dedicated Phase 2 coordinator layer that speaks in UI-ready summaries.
</research_summary>

<standard_stack>
## Standard Stack

The established libraries and tools for this phase:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | Xcode 26.3 stable toolchain | `MenuBarExtra`, window scenes, and menu content | Native menu bar scene support is the direct path for a lightweight resident utility |
| AppKit | System framework | `NSWorkspace` activation, app icons, and window activation edge cases | The menu bar flow still needs workspace integration and future window opening behavior |
| UniformTypeIdentifiers | System framework | Resolve the developer-text scope into declared content types | Prevents extension-only blind writes during the global batch apply |
| CoreServices Launch Services | System framework | Read and write editor handlers plus readback verification | Phase 1 already proved these wrappers are viable for the product |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Xcode-bundled | View-model and coordinator regression coverage | Use for aggregation logic and menu state transitions |
| SF Symbols | System | Lightweight status and current-selection glyphs | Best fit for a native menu utility with minimal iconography |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Default `MenuBarExtra` menu content | `MenuBarExtraStyle.window` popover-style UI | Window style gives more layout freedom, but the context favors native one-interaction menu behavior |
| Dedicated Phase 2 coordinator service | Direct Launch Services calls from the menu view model | Faster to start, but it mixes UI and mutation logic and makes partial-failure handling brittle |
| Real-time dynamic refresh only after writes | Also refresh on menu open | Refresh-on-open adds a small read cost, but it avoids stale summaries when users change defaults outside the app |

**Installation:**
```bash
# Apple-native stack only; Phase 2 keeps the repository dependency-free.
xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```text
App/
├── DefaultEditorSwitcherApp.swift
├── Features/
│   └── MenuBar/
│       ├── MenuBarContentView.swift
│       ├── MenuBarViewModel.swift
│       ├── MenuBarSection.swift
│       └── RulesWindowPlaceholderView.swift
├── Application/
│   └── GlobalText/
│       ├── GlobalTextStateService.swift
│       ├── GlobalTextSwitchCoordinator.swift
│       └── GlobalTextSwitchReport.swift
├── Domain/
│   └── Associations/
│       └── AssociationVerificationResult.swift
└── Infrastructure/
    ├── LaunchServices/
    └── Workspace/
Tests/
└── DefaultEditorSwitcherTests/
    ├── GlobalTextStateServiceTests.swift
    ├── GlobalTextSwitchCoordinatorTests.swift
    └── MenuBarViewModelTests.swift
```

### Pattern 1: Aggregate first, render second
**What:** Convert raw per-content-type state and write results into UI-facing summary models before SwiftUI touches them.
**When to use:** Always in Phase 2.
**Why:** The menu needs current editor text, mixed-state messaging, and grouped feedback, not raw arrays of `UTType` results.

### Pattern 2: Refresh on lifecycle edges
**What:** Load current state when the menu opens and reload after every apply attempt.
**When to use:** Every menu interaction cycle.
**Why:** Global defaults can change outside the app, and stale summary text makes the utility untrustworthy.

### Pattern 3: Keep the rules window real but lightweight
**What:** Add a real `WindowGroup` or equivalent scene ID now, even if it only hosts a placeholder.
**When to use:** This phase.
**Why:** Requirement `DIST-03` is about resident utility behavior plus a path into advanced configuration; a placeholder window satisfies the scene architecture without leaking Phase 4 scope.

### Anti-Patterns to Avoid
- **Blindly calling `verify` for undeclared types:** use `ContentTypeResolver.resolutions(for: .allText)` and skip unresolved or non-declared results deliberately.
- **Treating partial failure as a boolean false:** the UI needs a summary like `7 matched, 2 mismatched` or `unsupported for .svelte`.
- **Hiding non-primary editors completely:** the phase context explicitly says partial or unverified options should stay visible, just clearly demoted.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look easy but already have better building blocks:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Editor list ordering | A second menu-only ranking algorithm | `WorkspaceAppDiscovery` + `EditorRankingPolicy` | Keeps menu ordering aligned with the rest of the product |
| Current global editor summary | Hardcoded heuristics like "take the first text extension only" | A state service that reads every resolved declared type and collapses to unified or mixed state | Prevents misleading state when `.txt` and `.md` differ |
| Apply feedback | A generic success/failure toast | Aggregate counts and representative failures from `AssociationVerificationResult` | Lets the menu explain partial success without opening another window |
| Rules-window handoff | A fake disabled menu row | A real scene ID and `openWindow(id:)` path | Ensures the app remains resident while still exposing an advanced window |

**Key insight:** The menu bar UI should not become another systems-integration layer. It only needs to orchestrate state loading, action dispatch, and feedback display on top of the primitives already built in Phase 1.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Mixed current state is hidden behind a single editor label
**What goes wrong:** The menu shows one editor name even though the current handlers differ across text types.
**Why it happens:** The app reads only one representative extension or caches stale data.
**How to avoid:** Build a `GlobalTextStateService` that inspects the full declared `.allText` set and emits `.single(bundleID)`, `.mixed`, or `.unavailable`.
**Warning signs:** The menu says `VS Code` is current while `.md` still opens in another editor.

### Pitfall 2: Unsupported editors look like normal primary choices
**What goes wrong:** A partially declared IDE appears as a top-level switch action and the user assumes full coverage.
**Why it happens:** The menu ranks by recommendation only and ignores capability state.
**How to avoid:** Group `.full` candidates as primary actions and move `.partial` or `.unverified` rows into a lower section with explicit notes.
**Warning signs:** The menu list contains a recommended editor whose apply result always reports multiple unsupported types.

### Pitfall 3: The app loses its resident utility behavior
**What goes wrong:** Opening the placeholder window steals focus, creates a dock-first feeling, or the app has no clear menu bar anchor.
**Why it happens:** The app shell is treated like a standard window app with menu bar support bolted on later.
**How to avoid:** Make `MenuBarExtra` the primary scene and add a separate window scene only for the explicit `Open Rules Window...` action.
**Warning signs:** Launching the app creates an empty settings window, or the dock icon behavior becomes the main navigation path.
</common_pitfalls>

<code_examples>
## Code Examples

Repository-aligned patterns that should drive this phase:

### Expand the global developer-text scope
```swift
let resolutions = ContentTypeResolver.resolutions(for: .allText)
let declaredTypes = resolutions.compactMap { resolution in
    guard resolution.isDeclared, let type = resolution.type else {
        return nil
    }
    return type
}
```

### Discover ranked editor candidates for a representative text type
```swift
let discovery = WorkspaceAppDiscovery()
let candidates = discovery.discoverEditors(for: .plainText)
let primary = candidates.filter { $0.capability == .full }
let secondary = candidates.filter { $0.capability != .full }
```

### Verify one requested handler write and inspect the structured status
```swift
let verifier = LaunchServicesAssociationVerifier()
let result = verifier.verify(requestedBundleID: bundleID, for: type)

switch result {
case .matched:
    // count as success
case .mismatched, .unsupportedTarget, .writeFailed:
    // aggregate for feedback
}
```
</code_examples>

<implementation_notes>
## Implementation Notes

- Use `.plainText` as the representative discovery type for the menu candidate list so the menu remains fast and aligned with the global text promise; do not re-run discovery for every extension in the scope.
- Add a small immutable report model for apply results, with fields like `requestedBundleID`, `matchedCount`, `mismatchedCount`, `unsupportedCount`, `writeFailedCount`, and `sampleFailures`.
- Keep the menu content textual and native. Status glyphs should support the text, not replace it.
- The placeholder rules window should explicitly say that advanced language and extension rules arrive in later phases, so the Phase 2 window does not feel broken.
</implementation_notes>

## Validation Architecture

- **Wave 0 test harness:** the existing XCTest target is sufficient; no new framework setup is required.
- **State aggregation coverage:** add unit tests for unified, mixed, and unavailable global-text states, including mapping bundle IDs back to known editor display names where possible.
- **Switch coordinator coverage:** add tests proving that only declared `.allText` UTTypes are written, that result counts are aggregated correctly, and that mismatched or unsupported outcomes surface representative failures.
- **Menu view-model coverage:** add tests for load, apply, and refresh transitions, including the feedback text shown after success and partial failure.
- **Manual verification:** after implementation, launch the app, open the menu bar entry, confirm the current editor summary is visible, switch to a different editor, and verify the menu updates without opening the main window. Then use `Open Rules Window...` to confirm the resident utility can still open a secondary window scene.
- **Pass condition for Phase 2:** the menu accurately displays current global state, one-click apply updates the developer-text scope through the coordinator, the dropdown stays focused on app choices, and the rules window opens on demand.
