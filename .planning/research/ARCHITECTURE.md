# Architecture Research

**Domain:** macOS developer utility for default file editor switching
**Researched:** 2026-03-25
**Confidence:** MEDIUM-HIGH

## Standard Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                       UI / Scene Layer                      │
├─────────────────────────────────────────────────────────────┤
│  MenuBarExtra  │  Main Window  │  Restore Alerts           │
├─────────────────────────────────────────────────────────────┤
│                     Application Services                    │
├─────────────────────────────────────────────────────────────┤
│  Rule Engine   │  Editor Catalog  │  Verification Service  │
├─────────────────────────────────────────────────────────────┤
│                    System Integration Layer                 │
├─────────────────────────────────────────────────────────────┤
│  UTType Mapper │ Launch Services Writer │ NSWorkspace Reader│
├─────────────────────────────────────────────────────────────┤
│                      Local Persistence                      │
│  Preferences   │  Snapshot Store  │  Rule Definitions      │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Menu bar UI | Expose fast global text switching and status | SwiftUI `MenuBarExtra` with compact view models |
| Rules window | Manage language rules, custom extensions, restore actions | SwiftUI window with forms, tables, and validation |
| Editor catalog | Discover installed editors and rank them | `NSWorkspace` + built-in preferred bundle identifier list |
| Rule engine | Resolve precedence: custom extension > language > global text | Pure Swift domain layer with deterministic ordering |
| Association writer | Apply default handlers for resolved content types/extensions | Launch Services wrapper using content-type based updates |
| Verification service | Read back preferred handlers and detect partial failure | Launch Services / workspace read APIs plus local diffing |
| Snapshot store | Save previous system state and user presets | App Support JSON files plus lightweight preferences metadata |

## Recommended Project Structure

```text
App/
├── AppEntry/             # Scenes, app lifecycle, menu bar registration
├── Features/
│   ├── MenuBar/          # Quick switch UI
│   ├── RulesWindow/      # Language and custom rule management
│   └── Restore/          # Recovery and confirmation flows
├── Domain/
│   ├── Rules/            # Precedence logic and models
│   ├── Types/            # Language groups, extension packs, UTType mapping
│   └── Editors/          # Editor ranking and capability models
├── Infrastructure/
│   ├── LaunchServices/   # Read/write wrappers around system associations
│   ├── Workspace/        # Installed app discovery and icons
│   └── Persistence/      # Settings and snapshots
└── Resources/            # App assets and default language packs
```

### Structure Rationale

- **Feature-first UI folders:** keeps menu bar work separate from the heavier rules window.
- **Small domain core:** the precedence logic should be testable without UI or system APIs.
- **System wrappers isolated in Infrastructure:** makes Launch Services behavior mockable and limits platform glue.

## Architectural Patterns

### Pattern 1: Thin SwiftUI, Fat Services

**What:** Keep views declarative and move file-association logic into services.
**When to use:** Always for mutation-heavy utility apps.
**Trade-offs:** Slightly more boilerplate, much easier to test and reason about.

### Pattern 2: Snapshot Before Batch Mutation

**What:** Save all affected bindings before applying a batch change.
**When to use:** Any action that can affect multiple file types.
**Trade-offs:** Extra read I/O, but much safer recovery behavior.

### Pattern 3: Derived Preview Before Apply

**What:** Compute “what will change” before writing to Launch Services.
**When to use:** Language rules and custom extension edits.
**Trade-offs:** More implementation work, but it prevents hidden precedence surprises.

## Data Flow

### Request Flow

```text
User selects editor
    ↓
Rule Engine expands target scope
    ↓
UTType Mapper resolves affected content types/extensions
    ↓
Snapshot Store saves current handlers
    ↓
Launch Services Writer applies changes
    ↓
Verification Service re-reads effective handlers
    ↓
UI updates current state or shows recovery options
```

### State Management

```text
Persisted rules
    ↓
View models derive effective bindings
    ↓
User action mutates intent
    ↓
Services apply + verify
    ↓
Persisted state and current-status cache refresh
```

### Key Data Flows

1. **Global switch flow:** menu bar action updates the default editor for the text family set and refreshes current state.
2. **Override flow:** language/custom rule edits recompute the effective precedence map before any write occurs.
3. **Recovery flow:** restore action loads the last snapshot and reapplies prior handlers.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Single-user local utility | Single target, local persistence, no background daemon |
| Heavy power-user feature set | Add profile management and import/export boundaries |
| Team/shared workflows | Consider preset bundles or cloud sync only after v1 validation |

### Scaling Priorities

1. **First bottleneck:** correctness, not performance — fix partial writes and stale reads before optimizing UI polish.
2. **Second bottleneck:** rule complexity — introduce profile/domain boundaries only if custom rule volume actually grows.

## Anti-Patterns

### Anti-Pattern 1: UI Decides Precedence Inline

**What people do:** scatter rule-order logic across menu views and settings forms.
**Why it's wrong:** users see inconsistent results and recovery becomes impossible to reason about.
**Do this instead:** centralize precedence in one domain service.

### Anti-Pattern 2: Extension-Only Worldview

**What people do:** treat every rule as a raw extension string with no type system.
**Why it's wrong:** language packs become brittle and app discovery gets noisy.
**Do this instead:** keep both extension lists and resolved UTTypes, using UTType where the system supports it.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Launch Services | Thin synchronous wrapper plus verification pass | Core mutation point for default handlers |
| NSWorkspace | Query installed/eligible applications, icons, and app URLs | Useful for ranking and display |
| Developer ID + notarization | Build/export pipeline | Required for direct distribution confidence |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| UI ↔ Rule Engine | View model actions | No direct Launch Services calls from views |
| Rule Engine ↔ Launch Services wrapper | Typed requests/results | Makes failures explainable and testable |
| Launch Services wrapper ↔ Snapshot store | Pre/post apply hooks | Enables restore and audit |

## Sources

- https://developer.apple.com/documentation/swiftui/menubarextra
- https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28toopen%3A%29-ualk?language=objc
- https://developer.apple.com/documentation/coreservices/1444955-lssetdefaultrolehandlerforconten?changes=_6&language=objc
- https://developer.apple.com/documentation/uniformtypeidentifiers/uttypesourcecode
- https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html
- https://sindresorhus.com/default-browser

---
*Architecture research for: macOS developer utility for default file editor switching*
*Researched: 2026-03-25*
