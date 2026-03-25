# Requirements: Default Editor Switcher

**Current milestone:** none active
**Archived v1.0 scope:** `.planning/milestones/v1.0-REQUIREMENTS.md`

## Next Milestone Candidates

### Rules and Overrides

- [ ] **LANG-01**: User can assign a default editor specifically for Python files
- [ ] **LANG-02**: User can assign a default editor specifically for Web files, including `html`, `css`, `js`, `jsx`, `ts`, `tsx`, `vue`, and `svelte`
- [ ] **LANG-03**: User can assign a default editor specifically for Go files
- [ ] **LANG-04**: User can assign a default editor specifically for Java files
- [ ] **LANG-05**: User can assign a default editor specifically for Rust files
- [ ] **LANG-06**: User can assign a default editor specifically for Markdown files
- [ ] **LANG-07**: When a file matches both the global text scope and a language override, the language override wins
- [ ] **CUST-01**: User can create a custom extension rule that binds one or more extensions to a selected editor
- [ ] **CUST-02**: User can edit or delete an existing custom extension rule
- [ ] **CUST-03**: When a custom extension rule conflicts with a language override or the global text rule, the custom extension rule wins and the app explains the precedence
- [ ] **RULE-01**: User can open a main window that manages language overrides, custom extension rules, and restore actions
- [ ] **RULE-02**: User can see the effective editor for each built-in language category before applying changes

### State and Recovery

- [ ] **STAT-01**: User can view the current global text editor and the current effective editor for each built-in language category
- [ ] **STAT-02**: App saves a restore snapshot before any batch association change is applied
- [ ] **STAT-03**: User can restore the most recent snapshot from inside the app
- [ ] **STAT-04**: User can restore the system baseline captured during first-run setup

### Distribution Follow-Up

- [ ] **DIST-01-GA**: Team can execute a credentialed Developer ID archive, notarization, stapling, and installed `/Applications` validation run for the GA release path

### Productivity and Automation

- [ ] **PROD-01**: User can trigger the switcher with a configurable keyboard shortcut
- [ ] **PROD-03**: User can import or export rule presets between machines
- [ ] **AUTO-01**: User can trigger common editor-switch presets from Shortcuts or scriptable automation
- [ ] **AUTO-02**: User can maintain multiple named profiles, such as work, side project, or AI coding setup

## Notes

- The fully verified v1.0 requirement record lives in `.planning/milestones/v1.0-REQUIREMENTS.md`.
- Add traceability and milestone-specific grouping when the next milestone is formally planned.
