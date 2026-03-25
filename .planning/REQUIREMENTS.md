# Requirements: Default Editor Switcher

**Defined:** 2026-03-25
**Core Value:** 开发者可以在几秒内完成默认编辑器切换，而不是在 Finder 和系统设置里逐个文件类型手动修改。

## v1 Requirements

### Editor Discovery

- [ ] **DISC-01**: App can discover installed editors from a built-in preferred list and from system-declared handlers for supported text-like file types
- [ ] **DISC-02**: App can show each discovered editor with app icon, display name, and bundle identifier
- [ ] **DISC-03**: App only offers an editor for a target scope when the app can validate that the editor is eligible for that scope, or it clearly warns when support is partial

### Menu Bar UX

- [ ] **MENU-01**: User can open the app from the macOS menu bar without opening the main window
- [ ] **MENU-02**: User can see the current global text default editor directly in the menu bar UI
- [ ] **MENU-03**: User can switch the global text default editor from the menu bar in one interaction flow

### Global Text Switching

- [ ] **GLOB-01**: User can apply one editor as the default opener for the product’s built-in text-like file scope
- [ ] **GLOB-02**: Built-in text-like file scope includes a developer-oriented set such as `txt`, `md`, `mdx`, `json`, `yaml`, `yml`, `toml`, `xml`, `csv`, `log`, `ini`, `conf`, `cfg`, `env`, `sh`, `zsh`, and similar text/config formats
- [ ] **GLOB-03**: App verifies the result of a global switch and shows whether the effective default editor now matches the requested editor

### Language Overrides

- [ ] **LANG-01**: User can assign a default editor specifically for Python files
- [ ] **LANG-02**: User can assign a default editor specifically for Web files, including `html`, `css`, `js`, `jsx`, `ts`, `tsx`, `vue`, and `svelte`
- [ ] **LANG-03**: User can assign a default editor specifically for Go files
- [ ] **LANG-04**: User can assign a default editor specifically for Java files
- [ ] **LANG-05**: User can assign a default editor specifically for Rust files
- [ ] **LANG-06**: User can assign a default editor specifically for Markdown files
- [ ] **LANG-07**: When a file matches both the global text scope and a language override, the language override wins

### Custom Extension Rules

- [ ] **CUST-01**: User can create a custom extension rule that binds one or more extensions to a selected editor
- [ ] **CUST-02**: User can edit or delete an existing custom extension rule
- [ ] **CUST-03**: When a custom extension rule conflicts with a language override or the global text rule, the custom extension rule wins and the app explains the precedence

### Rules Window

- [ ] **RULE-01**: User can open a main window that manages language overrides, custom extension rules, and restore actions
- [ ] **RULE-02**: User can see the effective editor for each built-in language category before applying changes

### State and Recovery

- [ ] **STAT-01**: User can view the current global text editor and the current effective editor for each built-in language category
- [ ] **STAT-02**: App saves a restore snapshot before any batch association change is applied
- [ ] **STAT-03**: User can restore the most recent snapshot from inside the app
- [ ] **STAT-04**: User can restore the system baseline captured during first-run setup

### Distribution and Reliability

- [ ] **DIST-01**: User can install a signed and notarized build outside the Mac App Store
- [ ] **DIST-02**: When an association update fails fully or partially, the app shows an actionable error with the affected scope and a recovery path
- [ ] **DIST-03**: App can behave as a menu bar utility while still opening the main window for advanced configuration

## v2 Requirements

### Productivity

- **PROD-01**: User can trigger the switcher with a configurable keyboard shortcut
- **PROD-02**: User can launch the app automatically at login
- **PROD-03**: User can import or export rule presets between machines

### Automation

- **AUTO-01**: User can trigger common editor-switch presets from Shortcuts or scriptable automation
- **AUTO-02**: User can maintain multiple named profiles, such as work, side project, or AI coding setup

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mac App Store compatibility | v1 release strategy is direct download first |
| URL routing, browser-style rules, or opener interception | Different product category; would dilute the core file-association utility |
| Coverage for every non-text file type on macOS | v1 is explicitly developer-first and text/source oriented |
| Per-project or per-folder automatic switching | Too much complexity for initial launch; defer until core switching proves valuable |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DISC-01 | Phase 1 | Validated |
| DISC-02 | Phase 1 | Validated |
| DISC-03 | Phase 1 | Awaiting verification |
| MENU-01 | Phase 2 | Pending |
| MENU-02 | Phase 2 | Pending |
| MENU-03 | Phase 2 | Pending |
| GLOB-01 | Phase 2 | Pending |
| GLOB-02 | Phase 1 | Validated |
| GLOB-03 | Phase 2 | Pending |
| LANG-01 | Phase 3 | Pending |
| LANG-02 | Phase 3 | Pending |
| LANG-03 | Phase 3 | Pending |
| LANG-04 | Phase 3 | Pending |
| LANG-05 | Phase 3 | Pending |
| LANG-06 | Phase 3 | Pending |
| LANG-07 | Phase 3 | Pending |
| CUST-01 | Phase 4 | Pending |
| CUST-02 | Phase 4 | Pending |
| CUST-03 | Phase 4 | Pending |
| RULE-01 | Phase 4 | Pending |
| RULE-02 | Phase 4 | Pending |
| STAT-01 | Phase 5 | Pending |
| STAT-02 | Phase 5 | Pending |
| STAT-03 | Phase 5 | Pending |
| STAT-04 | Phase 5 | Pending |
| DIST-01 | Phase 6 | Pending |
| DIST-02 | Phase 6 | Pending |
| DIST-03 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after phase 01 execution review*
