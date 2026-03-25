# Roadmap: Default Editor Switcher

## Overview

这条路线从“先证明系统能力真实可用”开始，再尽快交付菜单栏里的核心价值，然后逐步补齐语言级规则、自定义扩展名、恢复机制和发布硬化。整体顺序刻意把 Launch Services 能力验证和用户信任机制放在 UI 扩展之前，避免做出漂亮但不可靠的壳。

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Discovery & Association Core** - Build the type catalog, editor discovery, and Launch Services foundation
- [ ] **Phase 2: Menu Bar Global Switch** - Deliver the fast global text-editor switching experience
- [ ] **Phase 3: Language Override Engine** - Add developer-oriented language buckets and override precedence
- [ ] **Phase 4: Rules Window & Custom Extensions** - Ship the advanced rules-management UI and custom extension bindings
- [ ] **Phase 5: State, Snapshot, and Restore** - Make the utility trustworthy with visibility and recovery
- [ ] **Phase 6: Release Hardening** - Prepare direct-download shipping, signing, notarization, and failure handling

## Phase Details

### Phase 1: Discovery & Association Core
**Goal**: Build the product’s file-type taxonomy, editor discovery model, and the verified Launch Services mutation/readback core.
**Depends on**: Nothing (first phase)
**Requirements**: [DISC-01, DISC-02, DISC-03, GLOB-02]
**UI hint**: no
**Success Criteria** (what must be TRUE):
  1. App can resolve the built-in text-like and language bucket scopes into concrete extensions and content types.
  2. App can list eligible editors with icon, name, bundle identifier, and capability metadata for a representative target scope.
  3. A prototype association writer can update and re-read default handlers for representative text/source-code types.
  4. Unsupported or partially supported editors are surfaced clearly enough to avoid misleading switch actions.
**Plans**: 3 plans

Plans:
- [ ] 01-01: Define file taxonomy, language buckets, and precedence-ready domain models
- [ ] 01-02: Build editor discovery and ranking using built-in preferences plus system eligibility
- [ ] 01-03: Implement Launch Services read/write wrappers and verification probes

### Phase 2: Menu Bar Global Switch
**Goal**: Deliver the simple `default-browser`-style menu bar flow for switching all text-like files to one editor.
**Depends on**: Phase 1
**Requirements**: [MENU-01, MENU-02, MENU-03, GLOB-01, GLOB-03, DIST-03]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can open the utility from the menu bar and see the current global text editor.
  2. User can switch the global text target from the menu bar in one short interaction flow.
  3. The menu bar UI reflects success or failure after a global switch without opening the main window.
  4. The app can stay resident as a menu bar utility while still exposing the main window on demand.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Build menu bar app shell, current-state summary, and editor list UI
- [ ] 02-02: Wire global text switch actions through the verified association writer
- [ ] 02-03: Add post-apply feedback, refresh, and entry points into the main window

### Phase 3: Language Override Engine
**Goal**: Add built-in language categories and make language-specific defaults override the global text rule.
**Depends on**: Phase 2
**Requirements**: [LANG-01, LANG-02, LANG-03, LANG-04, LANG-05, LANG-06, LANG-07]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can assign dedicated editors for Python, Web, Go, Java, Rust, and Markdown.
  2. Files in those categories open with the language-specific editor even when a different global text editor is active.
  3. The precedence model is deterministic and testable for overlapping file scopes.
**Plans**: 2 plans

Plans:
- [ ] 03-01: Implement language bucket definitions and effective-binding precedence logic
- [ ] 03-02: Apply and verify language-specific overrides against the system association layer

### Phase 4: Rules Window & Custom Extensions
**Goal**: Provide the advanced configuration window for override management and custom extension rules.
**Depends on**: Phase 3
**Requirements**: [CUST-01, CUST-02, CUST-03, RULE-01, RULE-02]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can open a main window dedicated to rule management.
  2. User can create, edit, and delete custom extension rules.
  3. The UI explains effective precedence when custom extension rules conflict with language or global rules.
  4. User can preview the effective editor for each built-in language category before saving changes.
**Plans**: 3 plans

Plans:
- [ ] 04-01: Build the rules window shell, navigation, and rule state models
- [ ] 04-02: Implement custom extension CRUD, validation, and conflict messaging
- [ ] 04-03: Surface effective bindings and apply flows in the advanced configuration UI

### Phase 5: State, Snapshot, and Restore
**Goal**: Make changes safe and understandable with current-state visibility, restore snapshots, and baseline recovery.
**Depends on**: Phase 4
**Requirements**: [STAT-01, STAT-02, STAT-03, STAT-04]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can inspect the current global text editor and effective language bindings in the app.
  2. The app captures a snapshot before batch updates that change multiple file associations.
  3. User can restore either the latest snapshot or the original baseline from inside the product.
  4. Restore operations are verified after apply and report any remaining mismatch.
**Plans**: 2 plans

Plans:
- [ ] 05-01: Implement state inspection, snapshot persistence, and baseline capture
- [ ] 05-02: Implement restore actions, verification, and user-facing recovery flows

### Phase 6: Release Hardening
**Goal**: Ship a trustworthy direct-download macOS product with clear failure handling and validated release artifacts.
**Depends on**: Phase 5
**Requirements**: [DIST-01, DIST-02]
**UI hint**: no
**Success Criteria** (what must be TRUE):
  1. A signed and notarized release artifact installs and launches cleanly outside the Mac App Store.
  2. Association failures show actionable messages that identify the failed scope and recovery path.
  3. Release validation covers signed/notarized behavior on a clean machine, not only debug builds.
**Plans**: 2 plans

Plans:
- [ ] 06-01: Build the release pipeline for signing, notarization, and install verification
- [ ] 06-02: Harden failure UX, error messaging, and release-check procedures

## Progress

**Execution Order:**
Phases execute in numeric order: 2 → 2.1 → 2.2 → 3 → 3.1 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Discovery & Association Core | 2/3 | In progress | - |
| 2. Menu Bar Global Switch | 0/3 | Not started | - |
| 3. Language Override Engine | 0/2 | Not started | - |
| 4. Rules Window & Custom Extensions | 0/3 | Not started | - |
| 5. State, Snapshot, and Restore | 0/2 | Not started | - |
| 6. Release Hardening | 0/2 | Not started | - |
