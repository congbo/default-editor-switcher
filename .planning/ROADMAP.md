# Roadmap: Default Editor Switcher

## Overview

这条路线从“先证明系统能力真实可用”开始，再尽快交付菜单栏里的核心价值，然后逐步补齐语言级规则、自定义扩展名、恢复机制和发布硬化。整体顺序刻意把 Launch Services 能力验证和用户信任机制放在 UI 扩展之前，避免做出漂亮但不可靠的壳。

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Discovery & Association Core** - Build the type catalog, editor discovery, and Launch Services foundation
- [x] **Phase 2: Menu Bar Global Switch** - Deliver the fast global text-editor switching experience
- [x] **Phase 3: Native Settings Window** - Add a native settings window for startup behavior, recommended apps, and language preferences
- [ ] **Phase 4: Release Hardening** - Prepare direct-download shipping, signing, notarization, and failure handling

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
- [x] 01-01: Define file taxonomy, language buckets, and precedence-ready domain models
- [x] 01-02: Build editor discovery and ranking using built-in preferences plus system eligibility
- [x] 01-03: Implement Launch Services read/write wrappers and verification probes

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
- [x] 02-01: Build menu bar app shell, current-state summary, and editor list UI
- [x] 02-02: Wire global text switch actions through the verified association writer
- [x] 02-03: Add post-apply feedback, refresh, and entry points into the main window

Verification:
- Automated checks and human verification passed; see `02-VERIFICATION.md` and `02-HUMAN-UAT.md`

### Phase 3: Native Settings Window
**Goal**: Deliver a native settings window using macOS-native components for startup behavior, recommended app configuration, and language preferences.
**Depends on**: Phase 2
**Requirements**: [PROD-02, DIST-03]
**UI hint**: yes
**Success Criteria** (what must be TRUE):
  1. User can enable or disable launch at login from the settings window.
  2. User can configure which recommended apps appear in the menu bar first-level dropdown, where only checked and installed full-support editors appear there and unchecked ones move to `More`.
  3. User can choose app language between Chinese, English, and follow-system mode, with system language as the default.
**Plans**: 3/3 plans executed

Plans:
- [x] 03-01: Build the settings window shell and launch-at-login controls
- [x] 03-02: Add configurable recommended menu apps and menu integration
- [x] 03-03: Add app-language selection and localize menu/settings copy

Verification:
- Automated test coverage is green, and manual verification passed; see `03-VALIDATION.md` and `03-UAT.md`

### Phase 4: Release Hardening
**Goal**: Ship a trustworthy direct-download macOS product with clear failure handling and validated release artifacts.
**Depends on**: Phase 3
**Requirements**: [DIST-01, DIST-02]
**UI hint**: no
**Success Criteria** (what must be TRUE):
  1. A signed and notarized release artifact installs and launches cleanly outside the Mac App Store.
  2. Association failures show actionable messages that identify the failed scope and recovery path.
  3. Release validation covers signed/notarized behavior on a clean machine, not only debug builds.
**Plans**: 2 plans

Plans:
- [ ] 04-01: Build the release pipeline for signing, notarization, and install verification
- [ ] 04-02: Harden failure UX, error messaging, and release-check procedures

## Progress

**Execution Order:**
Phases execute in numeric order: 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Discovery & Association Core | 3/3 | Complete | 2026-03-25 |
| 2. Menu Bar Global Switch | 3/3 | Complete | 2026-03-25 |
| 3. Native Settings Window | 3/3 | Complete | 2026-03-26 |
| 4. Release Hardening | 0/2 | Not started | - |
