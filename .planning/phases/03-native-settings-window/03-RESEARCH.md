# Phase 3: Native Settings Window - Research

**Researched:** 2026-03-26
**Domain:** native macOS settings architecture for startup behavior, configurable recommended menu apps, and app language selection
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from roadmap and insertion request)

### Locked Decisions
- Phase 3 delivers a real native settings window; it is not a web view, a custom inspector, or a placeholder-only screen.
- The settings window must include a launch-at-login control.
- The settings window must let the user configure which apps appear as recommended choices in the menu bar's first-level dropdown.
- The default recommended-app selection and ordering must be seeded from the app's existing curated global recommended editor list instead of introducing a new default ranking.
- The settings window must let the user choose app language between follow-system, Chinese, and English, with follow-system as the default.
- The menu bar remains the primary quick-switch surface; settings is the advanced configuration surface that feeds that menu rather than replacing it.

### the agent's Discretion
- Whether the settings surface stays as a dedicated `WindowGroup` or migrates to a SwiftUI `Settings` scene can be chosen based on the least disruptive integration with the current `openWindow` flow.
- Recommended-app editing can use drag reorder, explicit move controls, or another native list pattern as long as ordering is visible and deterministic.
- Language changes may apply live to app-owned SwiftUI text or on next window/menu reopen, provided the behavior is explicit and consistent.
- Preferences can live in one composed store or in several feature-specific stores so long as menu-bar reads and settings writes share a single source of truth.

### Deferred Ideas (OUT OF SCOPE)
- Language-specific file-association rules and custom extension CRUD
- Preset import/export and multi-profile management
- Release-signing, notarization, and installer verification work from Phase 4
- Any non-native plugin or sync system for settings storage

</user_constraints>

<research_summary>
## Summary

Phase 3 should convert the existing `Settings...` placeholder into a real native configuration surface backed by three explicit preference domains: launch at login, recommended menu apps, and app language. The current codebase already exposes the right integration seam for this work. `DefaultEditorSwitcherApp` has a resident `MenuBarExtra`, a dedicated secondary window scene, and a stable settings entry point; `MenuBarViewModel` already owns the first-level menu rows; `KnownEditors` and `EditorRankingPolicy` already define the curated recommendation order that should seed the new settings defaults. The right implementation strategy is to add a settings-specific application layer that persists user choices and then make the menu bar consume those preferences instead of hardcoded global catalog order.

Launch at login should be isolated behind a small wrapper around `ServiceManagement.SMAppService.mainApp`. Apple's current API is the right boundary for a direct-distributed macOS utility, but the phase should treat status reads, registration failures, and debug-versus-signed behavior as first-class states rather than burying them in SwiftUI view code. That keeps the UI native and testable while leaving signing-specific manual validation to Phase 4.

Recommended menu apps should not mutate `KnownEditors.catalog` directly. Instead, Phase 3 should introduce a stored ordered list of recommended bundle IDs plus a separate default enabled subset, filter the first-level menu against currently discovered eligible apps, and keep unchecked but eligible editors in `More` instead of backfilling or injecting the current editor. This keeps the user-facing customization narrow and explainable without breaking the menu's one-step switching behavior.

Language selection should be built on real localization resources and a persisted app-language preference, not a hand-rolled string-switching layer. The app already uses mostly SwiftUI-owned text, which makes a locale-override pipeline practical: define a stored `AppLanguage` enum with `.system`, `.english`, and `.simplifiedChinese`, map that to an optional locale override, inject it at the app root, and move app-owned copy into a string catalog. The key risk is partial localization caused by hardcoded strings currently living inside `MenuBarViewModel` and placeholder views, so the phase must include a pass that routes those strings through localizable resources from the first touch.

**Primary recommendation:** implement Phase 3 as a settings-foundation phase with one shared preference layer and three focused vertical slices, then keep Phase 4 free to focus on release hardening instead of mixing in unfinished settings plumbing.
</research_summary>

<standard_stack>
## Standard Stack

The established libraries and tools for this phase:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | Xcode 26.3 stable toolchain | Settings window layout, forms, toggles, pickers, and sectioned editor configuration UI | The existing app shell is already SwiftUI-first, and native controls are the product requirement |
| AppKit | System framework | Window activation behavior, app icon lookup, and any menu-bar edge cases while opening settings | The app already mixes AppKit with SwiftUI for workspace and menu integration |
| ServiceManagement | System framework | Launch-at-login status, register, and unregister behavior via `SMAppService` | This is Apple's supported modern API for login-item style app launching |
| Foundation + UserDefaults | System framework | Persist menu recommendation order/selection and app-language preference | Local-only preference state is sufficient for the current milestone |
| String Catalogs (`.xcstrings`) | Xcode resource format | English and Chinese app-owned copy for menu and settings UI | The phase requires real localization, not hardcoded translated branches |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Xcode-bundled | Store, ranking, and localization preference regression tests | Use for all preference and view-model behavior that can be verified without UI automation |
| UniformTypeIdentifiers | System framework | Keep menu candidate discovery anchored to `UTType.plainText` and existing type-resolution rules | Needed so recommendation customization stays aligned with the actual menu scope |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `SMAppService.mainApp` wrapper | Legacy `SMLoginItemSetEnabled` helper-based flow | Legacy helper flows add packaging complexity and are unnecessary for this direct app-launch toggle |
| Persisted recommended-app override list | Editing `KnownEditors.catalog` or changing static sort constants | Static mutation would make defaults and user customization indistinguishable and harder to test |
| String catalog + locale override | Manual `if language == ...` copy branches | Manual branching scales poorly and guarantees partial localization drift |
| Dedicated settings window view composition | Building all settings logic directly inside `MenuBarContentView` | Menu-bar code should remain focused on quick switching, not advanced configuration state |

**Installation:**
```bash
# Apple-native stack only; no third-party packages required for Phase 3.
xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```text
App/
├── DefaultEditorSwitcherApp.swift
├── Application/
│   ├── Settings/
│   │   ├── RecommendedMenuAppsStore.swift
│   │   └── SettingsSceneState.swift
│   ├── Startup/
│   │   └── LaunchAtLoginService.swift
│   └── Localization/
│       ├── AppLanguage.swift
│       └── AppLanguageStore.swift
├── Features/
│   ├── MenuBar/
│   │   ├── MenuBarContentView.swift
│   │   └── MenuBarViewModel.swift
│   └── Settings/
│       ├── SettingsWindowView.swift
│       ├── GeneralSettingsSection.swift
│       ├── RecommendedAppsSettingsSection.swift
│       └── LanguageSettingsSection.swift
└── Support/
    └── KnownEditors.swift
Tests/
└── DefaultEditorSwitcherTests/
    ├── LaunchAtLoginServiceTests.swift
    ├── RecommendedMenuAppsStoreTests.swift
    ├── AppLanguageStoreTests.swift
    └── MenuBarViewModelTests.swift
```

### Pattern 1: Preference overlay, not source-of-truth replacement
**What:** Keep the curated editor catalog as the product default, then layer persisted user overrides on top for recommendation order and inclusion.
**When to use:** Always for the first-level menu recommendation feature.
**Why:** The current curated list still defines the product's default behavior; Phase 3 only makes that list configurable.

### Pattern 2: Service wrapper between SwiftUI and system APIs
**What:** Wrap `SMAppService.mainApp` and preference persistence behind protocols and small testable adapters.
**When to use:** For launch-at-login and any environment-driven app-language logic.
**Why:** System APIs and static globals are hard to exercise directly in XCTest and should not leak into view code.

### Pattern 3: One settings window, independent feature sections
**What:** Build a root settings window that composes separate native sections for General, Menu Bar, and Language.
**When to use:** For the full phase.
**Why:** The three behaviors are related from a user perspective but should still be editable and testable independently.

### Pattern 4: Localize app-owned text at the boundary
**What:** Move menu and settings copy into localizable resources at the same time the language preference is introduced.
**When to use:** As soon as language selection work starts.
**Why:** Leaving strings in view models or ad hoc literals creates a half-localized app where the preference appears broken.

### Anti-Patterns to Avoid
- **Directly persisting recommendation state by display name:** store bundle IDs, because display names can vary by app version or locale.
- **Letting the recommended-app preference hide the active editor completely:** the menu must still surface the current editor even when it is not in the curated set.
- **Calling `SMAppService` from a SwiftUI `Toggle` binding body:** failures and status changes need an explicit view-model boundary.
- **Localizing only the settings window:** the menu bar labels, summaries, and settings action titles must follow the same language preference or the feature will feel inconsistent.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look easy but already have better building blocks:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Launch-at-login plumbing | A custom login-item helper target before it is needed | `SMAppService.mainApp` behind `LaunchAtLoginService` | Keeps the phase narrow and aligned with Apple's current API |
| Recommendation defaults | A new hardcoded list separate from the current menu order | `KnownEditors.catalog` / `menuSortOrder` as the seed source | Prevents a second competing definition of "recommended" |
| Menu personalization | A settings-only list that ignores installed eligibility | Store ordered bundle IDs, then intersect with `WorkspaceAppDiscovery` results at runtime | Keeps recommendations realistic on the current machine |
| Language switching | Runtime string maps or duplicated translated literals in code | `.xcstrings` resources plus a persisted language enum and locale override | Scales with the app and keeps future phases localizable |

**Key insight:** Phase 3 is mostly about moving currently implicit product defaults into explicit, user-editable settings without regressing the menu bar's low-friction switching path.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Launch-at-login looks enabled even when registration failed
**What goes wrong:** The toggle appears on, but `SMAppService` did not actually register or unregister successfully.
**Why it happens:** UI state is treated as the source of truth instead of re-reading service status or surfacing errors.
**How to avoid:** Model status explicitly, wrap failures into a user-facing error state, and re-read status after every toggle attempt.
**Warning signs:** The toggle changes immediately but flips back after relaunch, or debug builds behave differently without any explanatory message.

### Pitfall 2: Recommended-app settings break the first-level menu promise
**What goes wrong:** The menu and settings window drift out of sync, the menu backfills rows the user intentionally unchecked, or the current editor is forced into the first level even when it was explicitly removed.
**Why it happens:** Stored preferences are applied as an absolute list rather than an ordered recommendation overlay.
**How to avoid:** Rebuild menu rows only after persisted configuration updates, enforce a minimum of one checked recommendation in settings, and let unchecked editors stay in `More`.
**Warning signs:** A configured list of three apps makes the top-level menu permanently show only three choices even when more eligible apps are installed.

### Pitfall 3: Language selection only localizes the new settings window
**What goes wrong:** Settings text changes language, but menu copy and summaries stay in the old language.
**Why it happens:** Hardcoded strings remain in `MenuBarViewModel` and menu content.
**How to avoid:** Include a dedicated string-localization pass in the language plan and verify both the settings window and menu bar strings.
**Warning signs:** The settings picker says "English" while the menu still shows mixed Chinese and English labels.

### Pitfall 4: Phase 3 accidentally turns into rules-management scope creep
**What goes wrong:** The implementation starts adding language-specific file association rules or custom extension editing.
**Why it happens:** The new settings window creates a temptation to finish every advanced preference at once.
**How to avoid:** Keep Phase 3 limited to settings for startup, menu recommendations, and app language; keep rule editing for later planned phases.
**Warning signs:** New settings code starts referencing `LanguageBucket` rule assignment flows or custom-extension CRUD before the settings foundation is complete.
</common_pitfalls>

<code_examples>
## Code Examples

Repository-aligned patterns that should guide this phase:

### Wrap launch-at-login behind a service boundary
```swift
import ServiceManagement

struct LaunchAtLoginService {
    func currentStatus() -> SMAppService.Status {
        SMAppService.mainApp.status
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

### Seed configurable recommendations from the current curated order
```swift
let defaultRecommendedBundleIDs = KnownEditors.catalog.map(\.bundleID)
let configuredOrder = storedBundleIDs.isEmpty ? defaultRecommendedBundleIDs : storedBundleIDs

let orderedCandidates = configuredOrder.compactMap { bundleID in
    discoveredCandidates.first(where: { $0.bundleID == bundleID })
}
```

### Inject an app-language preference as a locale override
```swift
enum AppLanguage: String {
    case system
    case english
    case simplifiedChinese

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .simplifiedChinese: return "zh-Hans"
        }
    }
}
```
</code_examples>

<implementation_notes>
## Implementation Notes

- Keep the existing menu action title as `Settings...`, but rename the underlying placeholder view and scene IDs away from `RulesWindow` so the code matches the product boundary.
- Treat `KnownEditors.catalog` as the immutable seed list and store only the user's ordered bundle-ID overrides plus enabled/disabled selection state.
- The recommended-app settings UI should operate on installed, currently eligible candidates first, but still show configured bundle IDs that are temporarily unavailable in a disabled or explanatory state so the order does not silently disappear.
- Move menu and settings copy into localization resources early in the phase so newly introduced settings UI does not add more hardcoded English literals.
- Expect manual verification of launch-at-login to remain necessary on a real macOS machine, especially because registration behavior is more meaningful on signed or packaged builds than inside every debug scenario.
- Requirement mapping in `REQUIREMENTS.md` is currently incomplete for recommendation customization and app-language preference. Planning can proceed, but a later requirements sync should formalize those behaviors.
</implementation_notes>

## Validation Architecture

- **Wave 0 test harness:** the existing XCTest target is sufficient; no new framework or helper target is required for planning this phase.
- **Startup behavior coverage:** add tests for the launch-at-login wrapper and general-settings state transitions so service status, toggle actions, and failure handling remain deterministic.
- **Recommendation customization coverage:** add tests proving the stored recommended bundle-ID order seeds from the curated list, the default enabled set includes `TextEdit` and `Qoder`, live updates reach the menu immediately, and unchecked/current editors stay in `More`.
- **Localization preference coverage:** add tests for `AppLanguage` persistence, locale mapping, and any menu/settings view-model strings that should react to the selected app language.
- **Manual verification:** build and run the app, open `Settings...`, toggle launch at login and verify the status refreshes, change recommended menu apps and confirm the first-level menu ordering changes without losing the current editor, then switch between follow-system, English, and Chinese to confirm both the settings window and menu bar copy update consistently.
- **Pass condition for Phase 3:** the placeholder settings window is replaced with a real native configuration surface, launch-at-login can be toggled through a system-backed service wrapper, the menu's recommended first-level app list follows stored user preferences without backfill or forced current-editor injection, and app-owned strings respect the selected language preference.
