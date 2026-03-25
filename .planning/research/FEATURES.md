# Feature Research

**Domain:** macOS developer utility for default file editor switching
**Researched:** 2026-03-25
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| One-click menu bar switching for the primary target set | The reference experience from `Default Browser` is fast and visible | MEDIUM | This is the product’s defining interaction |
| Installed editor discovery with icons and app names | Users won’t manually type bundle IDs | MEDIUM | Must prioritize common editors while still showing eligible system apps |
| “Current default” visibility | Preference-changing tools need trust and feedback | LOW | Show current global editor and active overrides |
| Settings window for advanced rules | Language-specific and custom-extension logic won’t fit a simple menu | MEDIUM | Secondary but still required for v1 |
| Reliable verification after change | Users need confidence the system association actually changed | MEDIUM | Read back after write and show errors when mismatched |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Developer-first language buckets | Makes the product feel purpose-built for coders instead of generic file management | MEDIUM | Prebuilt `Python`, `Web`, `Go`, `Java`, `Rust`, `Markdown`, etc. |
| Global text rule plus language overrides | Solves the real “switch IDE fast, keep exceptions” workflow | MEDIUM | Core product shape confirmed by user interviews in this thread |
| Custom extension rules | Lets teams support niche or internal file types without waiting for shipped presets | MEDIUM | Needs clear precedence and validation |
| Restore previous/system baseline | Reduces fear around bulk changes | MEDIUM | Strong trust feature for a utility making system-wide changes |
| Editor-first UX and recommended app ordering | Faster than generic “Open With” style lists | LOW | Built-in ranking makes the product feel curated |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| URL/app routing rules like Velja | Power users often ask for rules once they see any chooser tool | It changes the product into an interceptor/router instead of a direct system-default editor switcher | Keep v1 focused on changing default file associations directly |
| Support every file class on macOS | Sounds comprehensive | Bloats UI and testing surface far beyond the developer text-file use case | Focus on text, source code, markdown, config, and custom extensions |
| Mac App Store-first distribution | Feels safer from a publishing standpoint | Similar products report sandboxing blocks much of the required functionality | Ship direct with Developer ID + notarization |

## Feature Dependencies

```text
App discovery
    └──requires──> Content-type taxonomy
                           └──requires──> Rule engine

Rule engine
    └──requires──> Launch Services writer
                           └──requires──> Verification + snapshot restore

Settings window ──enhances──> Language rules + custom extension rules

Keyboard shortcut automation ──enhances──> Menu bar switching
```

### Dependency Notes

- **App discovery requires content-type taxonomy:** the app must know which editors are relevant for which language or text family before ranking them.
- **Rule engine requires Launch Services writer:** a UI without a reliable mutation path is fake progress.
- **Verification requires snapshot restore:** once multiple content types are updated in a batch, rollback is the safety net.

## MVP Definition

### Launch With (v1)

- [ ] Menu bar action to switch all supported text-like file types to one editor
- [ ] Built-in developer-oriented language categories with per-language editor overrides
- [ ] Custom extension rules
- [ ] Current-state visibility for global and override rules
- [ ] Restore previous snapshot or baseline
- [ ] Signed and notarized direct-download build

### Add After Validation (v1.x)

- [ ] Global keyboard shortcut to open the switcher — add if menu bar-only access proves too slow
- [ ] Launch at login — add if users expect the utility always resident after reboot
- [ ] Import/export presets — add if users request team sharing or machine migration

### Future Consideration (v2+)

- [ ] Shortcuts app integration for automation
- [ ] Multiple named profiles, such as “work”, “personal”, or “AI coding”
- [ ] Deeper language packs and framework-specific presets

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Global text switching | HIGH | MEDIUM | P1 |
| Menu bar UI | HIGH | MEDIUM | P1 |
| Editor discovery | HIGH | MEDIUM | P1 |
| Language overrides | HIGH | MEDIUM | P1 |
| Custom extension rules | HIGH | MEDIUM | P1 |
| State visibility + restore | HIGH | MEDIUM | P1 |
| Signed/notarized release | HIGH | MEDIUM | P1 |
| Keyboard shortcut | MEDIUM | LOW-MEDIUM | P2 |
| Import/export profiles | MEDIUM | MEDIUM | P2 |
| Shortcuts automation | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Default Browser | Velja | Our Approach |
|---------|-----------------|-------|--------------|
| Fast menu bar switching | Strong | Strong | Match the simple, low-friction menu bar flow |
| Advanced rules | Minimal by design | Very strong | Keep only file-type rules relevant to editors, not URL routing |
| Developer-specific presets | No | Browser-focused | Make this a primary differentiator |
| Direct system-default mutation | Yes | Not the core model | Keep this as the product’s core behavior |

## Sources

- https://sindresorhus.com/default-browser
- https://sindresorhus.com/velja
- Apple platform docs cited in other research files for type systems, app discovery, and distribution constraints

---
*Feature research for: macOS developer utility for default file editor switching*
*Researched: 2026-03-25*
