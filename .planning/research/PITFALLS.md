# Pitfalls Research

**Domain:** macOS developer utility for default file editor switching
**Researched:** 2026-03-25
**Confidence:** MEDIUM

## Critical Pitfalls

### Pitfall 1: Assuming every editor declares every file type correctly

**What goes wrong:**
The app lists an editor as available, but Launch Services or `NSWorkspace` doesn’t consider it a valid editor for the selected content type. Users then see failed switches or misleading availability.

**Why it happens:**
Developer tools are inconsistent in how broadly they declare document types and roles.

**How to avoid:**
Use a two-layer catalog: built-in preferred editor ranking plus live capability validation per target type before offering a switch action.

**Warning signs:**
Editors appear in the UI but verification reads back a different default handler, or the editor is missing for only some extensions in a language bucket.

**Phase to address:**
Phase 1

---

### Pitfall 2: Precedence rules are not obvious to users

**What goes wrong:**
Users think “set all text to Cursor” failed because `.py` still opens in PyCharm, when in fact a language override is winning.

**Why it happens:**
The product intentionally supports both global and narrower rules, which creates ambiguity without a visible precedence model.

**How to avoid:**
Make precedence deterministic and visible: custom extension > language override > global text rule. Show effective target and conflict warnings in the main window.

**Warning signs:**
Support requests around “switch didn’t work” that are actually precedence misunderstandings.

**Phase to address:**
Phase 3

---

### Pitfall 3: Batch updates leave the system in a partially changed state

**What goes wrong:**
Some content types are updated while others fail, producing an inconsistent machine state that is hard to unwind manually.

**Why it happens:**
Bulk editor switching affects many extensions/types and can fail mid-operation for capability or permission reasons.

**How to avoid:**
Snapshot before writes, verify after each batch, and offer restore/retry flows when read-back differs from intended state.

**Warning signs:**
The current-state view does not match the requested target editor for all files in the same logical group.

**Phase to address:**
Phase 5

---

### Pitfall 4: Building for the wrong distribution model too late

**What goes wrong:**
The team invests in an App Store-compatible sandboxed design and only later discovers the functionality envelope is too tight for the intended utility behavior.

**Why it happens:**
Direct distribution, sandboxing, and system-integration capabilities are a product decision as much as an engineering one.

**How to avoid:**
Commit to Developer ID + notarized direct download from the start, and validate the capability on a clean machine before polishing secondary features.

**Warning signs:**
Late-stage entitlement churn, inconsistent behavior between debug and release builds, or unexplained failures in signed builds only.

**Phase to address:**
Phase 6

---

### Pitfall 5: The app behaves like a giant rules engine instead of a fast utility

**What goes wrong:**
The product accumulates browser-router style rules, complex conditions, and too many scopes, making the simple menu bar action harder to trust and slower to use.

**Why it happens:**
Utilities that change defaults often attract power-user requests for more automation and more rule types.

**How to avoid:**
Keep the core contract narrow in v1: direct editor switching for text-like file types, language overrides, and custom extensions only.

**Warning signs:**
Roadmap items start referencing URL matching, app-of-origin routing, schedules, or workspace-aware behaviors.

**Phase to address:**
Phase 2 through Phase 4

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hard-code only extensions with no type abstraction | Faster MVP coding | Painful to maintain language packs and custom rule resolution | Acceptable only in initial proof-of-concept spikes |
| Skip snapshot restore | Less persistence code | High-risk user trust failures after partial writes | Never for release builds |
| Couple menu bar UI directly to system APIs | Faster demo | Hard-to-test state bugs and stale UI | Never for production |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Launch Services | Treat write as success without re-reading | Verify effective handler after applying each logical batch |
| NSWorkspace | Assume returned apps are already in desired display order | Apply a built-in ranking layer for common editors |
| Notarization | Only test unsigned or debug builds | Test signed and notarized archives on a clean machine |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full rescans on every menu open | Laggy menu bar interaction | Cache editor catalog and refresh only when needed | Noticeable immediately on slower machines |
| Recomputing all rules for every row repaint | Choppy settings window | Compute derived effective bindings once per change event | Noticeable as rule count grows |
| Excessive verification calls after every tiny UI edit | Slow rule editing | Apply verification after save/apply actions, not every keystroke | Breaks UX as custom rule count rises |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Shipping unsigned or unnotarized direct builds | Gatekeeper warnings reduce install trust | Sign with Developer ID and notarize release artifacts |
| Treating arbitrary user extensions as safe without validation | Broken or unintended rules | Validate extension format and show scope preview before apply |
| Persisting opaque restore state without schema/versioning | Restore failures across app updates | Version snapshot payloads from the start |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Hiding why a file still opens in another editor | User thinks app is broken | Show effective rule source and precedence clearly |
| Overloading the menu bar dropdown with advanced settings | Slower primary workflow | Keep menu bar for fast switch only; push complexity to main window |
| Using generic app lists with no curation | Users can’t quickly find expected editors | Prioritize common developer editors first |

## "Looks Done But Isn't" Checklist

- [ ] **Global switch:** verify all targeted text-like types, not just `.txt`
- [ ] **Language override:** verify it wins over the global rule for the same file family
- [ ] **Custom extension rule:** verify conflict handling when extension also belongs to a language bucket
- [ ] **Release build:** verify signed/notarized archive behaves the same as debug build

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Partial batch write | MEDIUM | Load last snapshot, reapply previous handlers, show which targets failed |
| Broken precedence after rule edits | LOW | Recompute effective bindings, highlight conflicts, let user disable overrides |
| Release-only signing/distribution issue | MEDIUM-HIGH | Re-sign, notarize, test on clean machine, and document the verified release path |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Incomplete editor capability detection | Phase 1 | Known editors and system-eligible apps match expected targets |
| Precedence confusion | Phase 3 | Effective rule source is visible and consistent |
| Partial batch writes | Phase 5 | Restore path succeeds after a forced failure simulation |
| Wrong distribution model | Phase 6 | Signed/notarized build passes clean-machine install and run checks |
| Scope creep into router/rules engine | Phase 2-4 | Menu bar stays simple and settings remain file-rule focused |

## Sources

- https://sindresorhus.com/default-browser
- https://sindresorhus.com/velja
- https://developer.apple.com/macos/distribution/
- https://developer.apple.com/developer-id/
- https://developer.apple.com/documentation/coreservices/1444955-lssetdefaultrolehandlerforconten?changes=_6&language=objc
- https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28toopen%3A%29-ualk?language=objc

---
*Pitfalls research for: macOS developer utility for default file editor switching*
*Researched: 2026-03-25*
