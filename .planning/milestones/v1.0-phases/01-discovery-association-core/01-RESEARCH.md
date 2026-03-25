# Phase 1: Discovery & Association Core - Research

**Researched:** 2026-03-25
**Domain:** macOS default file-association infrastructure for a native developer utility
**Confidence:** MEDIUM-HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- The built-in "all text files" scope for v1 uses a developer-strict set rather than a broad generic text umbrella.
- Source-code extensions are included in the global text baseline from the start, not held back exclusively for later language buckets.
- Language-specific rules introduced in later phases are an override layer on top of the global text baseline, not a separate parallel scope model.
- Editor lists should be organized in two tiers: recommended editors first, then other system-eligible applications.
- Recommended editors should use a hybrid ranking model: a global preferred list for common developer editors, plus lightweight per-language weighting for specific buckets in later phases.
- System-declared eligible applications should still be discoverable even when they are not part of the curated recommended editor list.

### the agent's Discretion
- Partial-support handling strategy for editors that only cover some files in a target scope can be determined during research and planning for this phase.
- Verification granularity after Launch Services writes can be determined during research and planning for this phase, as long as the result is reliable enough to support later restore and UX work.

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.

</user_constraints>

<research_summary>
## Summary

Phase 1 should establish a native Swift macOS foundation that models file scopes with `UTType`, discovers candidate editors via system APIs, and isolates Launch Services writes behind a thin adapter that can be tested with mocks and validated with a small real-system probe. Apple’s current support pages show Xcode 26.3 as the latest stable release line and Xcode 26.4 RC as newer but not yet the stable baseline, so planning should target stable Xcode 26.3 semantics and current system frameworks rather than private or legacy tooling. Inference from Apple’s support matrix: a modern macOS deployment target such as macOS 14+ is a practical floor for a polished utility without taking on old-system compatibility drag.

The standard approach is not to hand-roll discovery or type resolution from raw extensions and `/Applications` scans. Apple’s file-type ecosystem is centered on document declarations in app bundles and Launch Services’ database. `UTTypeSourceCode` is explicitly documented as conforming to `UTTypeText`, which makes the user’s desired model viable: a global developer-text baseline can include source-code files, while later language buckets act as narrower overrides. The research implication is that the planner should separate the phase into: 1) taxonomy and scope modeling, 2) discovery and ranking, and 3) Launch Services mutation plus verification.

The highest-risk area is not UI but correctness. App discovery can be incomplete or noisy because editor bundles vary in how fully they declare supported content types; Launch Services can also produce a difference between “requested handler” and “effective handler” if a target app lacks the right role declaration. Phase 1 therefore needs both automated tests around taxonomy/ranking and at least one real-system verification probe for representative types like `.txt`, `.md`, and `.py`.

**Primary recommendation:** Build a testable association core around `UTType` + `NSWorkspace` + Launch Services C APIs, and make readback verification a first-class part of the design instead of an afterthought.
</research_summary>

<standard_stack>
## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Xcode | 26.3 stable | Build, test, sign, and archive the native macOS app | Apple’s support page lists 26.3 as current stable while 26.4 is RC; stable Xcode is the safest planning baseline |
| Swift | 6.2.x with Swift 6/5 language modes | Main implementation language | Native access to AppKit, CoreServices, and modern SwiftUI/App lifecycle APIs |
| UniformTypeIdentifiers | System framework | Convert filename extensions into declared or dynamic UTTypes and reason about conformance | Apple’s current type model is UTType-first rather than legacy UTI constants |
| AppKit / NSWorkspace | System framework | Discover eligible applications and app metadata | System-supported path to app URLs and workspace metadata |
| CoreServices Launch Services APIs | System framework | Read and write preferred document handlers by content type and role | This is the system layer the product exists to wrap |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| XCTest | Xcode-bundled | Stable unit/integration test harness for a fresh macOS Xcode project | Use for Phase 1 because command-line `xcodebuild test` integration is straightforward |
| SwiftUI | System framework | App shell and future menu bar/settings scenes | Phase 1 only needs minimal app scaffolding, but later phases will build on it |
| Foundation | System framework | Persistence primitives, bundle parsing, URL handling | Needed everywhere, especially for bundle identifiers and file URLs |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| XCTest | Swift Testing | Swift Testing is modern and promising, but XCTest is lower-risk for a brand-new Xcode project and phase validation commands |
| `UTType`-based taxonomy | Extension-only taxonomy | Extension-only is simpler short-term, but loses conformance information and creates more brittle overrides |
| `NSWorkspace` + Launch Services | Manual `/Applications` scanning and plist parsing only | Manual scans miss nonstandard locations and duplicate logic already maintained by the system |

**Installation:**
```bash
# Apple-native stack; no third-party dependencies required for Phase 1.
# Expected validation command after scaffold exists:
xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```text
DefaultEditorSwitcher.xcodeproj
App/
├── DefaultEditorSwitcherApp.swift
├── Domain/
│   ├── Types/
│   │   ├── FileScope.swift
│   │   ├── LanguageBucket.swift
│   │   └── ContentTypeResolver.swift
│   ├── Editors/
│   │   ├── EditorCandidate.swift
│   │   └── EditorRankingPolicy.swift
│   └── Associations/
│       ├── PreferredHandler.swift
│       └── AssociationVerificationResult.swift
├── Infrastructure/
│   ├── Workspace/
│   │   ├── WorkspaceAppDiscovery.swift
│   │   └── BundleDocumentTypeReader.swift
│   └── LaunchServices/
│       ├── LaunchServicesClient.swift
│       └── LaunchServicesAssociationVerifier.swift
└── Support/
    └── KnownEditors.swift
Tests/
└── DefaultEditorSwitcherTests/
    ├── FileScopeCatalogTests.swift
    ├── EditorRankingPolicyTests.swift
    └── LaunchServicesClientTests.swift
```

### Pattern 1: Domain-first type modeling
**What:** Model scopes such as `allText`, `python`, and `markdown` as domain objects that resolve to extensions and UTTypes, rather than scattering file extensions through service code.
**When to use:** Immediately; this is the core abstraction for later overrides.
**Example:**
```swift
import UniformTypeIdentifiers

enum FileScope {
    case allText
    case language(LanguageBucket)
    case customExtensions(Set<String>)
}

enum LanguageBucket: String {
    case python, web, go, java, rust, markdown
}
```

### Pattern 2: Thin system adapters with protocol seams
**What:** Wrap `NSWorkspace` and Launch Services functions behind small protocols/clients so logic can be tested without mutating the machine during unit tests.
**When to use:** Always for this phase.
**Example:**
```swift
protocol WorkspaceDiscovering {
    func applicationURLs(for contentType: UTType) -> [URL]
}

protocol PreferredHandlerWriting {
    func setDefaultHandler(bundleID: String, for contentType: UTType) throws
}
```

### Pattern 3: Verify after every mutation batch
**What:** Treat “write preferred handler” and “read back effective handler” as one logical operation.
**When to use:** Every time the app attempts a change to multiple file types.
**Example:**
```swift
let requested = "com.microsoft.VSCode"
try launchServicesClient.setDefaultHandler(bundleID: requested, for: type)
let effective = launchServicesClient.currentEditorBundleID(for: type)
```

### Anti-Patterns to Avoid
- **Extension lists embedded in UI code:** makes later override logic inconsistent and hard to audit.
- **Discovery by app name only:** bundle display names are unstable compared with bundle identifiers.
- **Assuming Launch Services writes are self-verifying:** without readback, partial support and role mismatches look like success.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Type resolution from file extensions | A custom extension-to-category registry as the only source of truth | `UTType(filenameExtension:)` plus explicit fallback tables for developer scopes | Apple documents that the initializer returns the corresponding type when recognized, and otherwise a dynamic undeclared type |
| App discovery for supported editors | Scanning `/Applications` and matching names like “VS Code” | `NSWorkspace`-based discovery plus bundle metadata | The system already tracks which apps can open which document types |
| Capability ranking | A ranking system that trusts only curated editor names | Hybrid ranking layered on top of system-eligible results | Keeps the product curated without hiding legitimate system handlers |

**Key insight:** The system already has a file-association database. The product’s value comes from modeling, curation, and safe mutation on top of that database, not from reimplementing it.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Dynamic UTTypes hide unsupported or unknown extensions
**What goes wrong:** An extension resolves to a dynamic type that doesn’t conform to the expected public text hierarchy, and the app silently treats it as fully supported.
**Why it happens:** Apple’s initializer can return a dynamic, undeclared type when the extension is unknown to the system.
**How to avoid:** Keep an explicit developer-strict extension registry as the scope baseline, then resolve each extension to UTType when possible and record whether the type is declared/public.
**Warning signs:** Tests show `.env`, `.toml`, or niche config extensions resolving inconsistently across machines.

### Pitfall 2: Editor discovery produces noisy or misleading results
**What goes wrong:** The app lists editors that are technically installed but not good candidates for the target scope, or misses editors that under-declare content types.
**Why it happens:** Launch Services ranking depends on bundle declarations such as `LSItemContentTypes`, `CFBundleTypeRole`, and `LSHandlerRank`, and editor vendors vary in quality.
**How to avoid:** Separate “recommended” from “other eligible”, store bundle IDs, and support capability states like `full`, `partial`, and `unverified`.
**Warning signs:** A Python bucket offers a text editor with no meaningful `.py` declaration, or a curated editor appears missing until a manual override table is added.

### Pitfall 3: A write appears successful but the effective handler is unchanged
**What goes wrong:** The mutation path returns success, but files still open in the old app or only some content types switch.
**Why it happens:** Role mismatches, incomplete app declarations, or Launch Services database behavior can break the expectation that “requested == effective”.
**How to avoid:** Design the service API around requested handler + readback result, and treat mismatches as a first-class verification outcome.
**Warning signs:** `.txt` changes but `.md` or `.py` stays behind after the same batch write.
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources:

### Resolve a filename extension into a UTType
```swift
import UniformTypeIdentifiers

let pyType = UTType(filenameExtension: "py")
let sourceCodeType = UTType.sourceCode
let isTextLike = pyType?.conforms(to: .text) == true
let isSourceCode = pyType?.conforms(to: sourceCodeType) == true
```
Source: Apple documents `UTTypeSourceCode` as `public.source-code` and states that it conforms to `UTTypeText`; Apple also documents that the filename-extension initializer returns a dynamic undeclared type if the system doesn’t recognize the extension.

### Discover applications that can open a content type
```swift
import AppKit
import UniformTypeIdentifiers

let type = UTType.plainText
let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: type)
```
Source: Apple’s `NSWorkspace.urlsForApplications(toOpen:)` documentation page for AppKit.

### Set a preferred editor for a content type
```swift
import CoreServices
import UniformTypeIdentifiers

let type = UTType.plainText
let bundleID = "com.microsoft.VSCode" as CFString
let status = LSSetDefaultRoleHandlerForContentType(
    type.identifier as CFString,
    LSRolesMask.editor,
    bundleID
)
```
Source: Apple’s `LSSetDefaultRoleHandlerForContentType` documentation page in CoreServices.
</code_examples>

<sota_updates>
## State of the Art (2024-2026)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Legacy UTI / MobileCoreServices-centric type code | `UniformTypeIdentifiers.UTType` as the modern app-facing API | Modern Apple platform era; current docs center UTType | Use UTType in the domain layer and bridge to CFString identifiers only at the Launch Services boundary |
| `altool` notarization flow | `notarytool` / current Xcode notarization flow | Apple stopped accepting `altool`/Xcode 13-era uploads on 2023-11-01 | Phase 6 planning should not use old notarization instructions |
| Manual status-item construction for all menu bar apps | `MenuBarExtra` for many modern menu bar cases | Modern SwiftUI releases | Relevant for later UI phases, but not required for Phase 1 |

**New tools/patterns to consider:**
- **Hybrid ranking model:** system eligibility plus curated preferred editors gives better developer UX than either pure system order or a hardcoded-only list.
- **Verification-first mutation APIs:** model requested and effective handlers together so restore and error UX remain grounded later.

**Deprecated/outdated:**
- **`altool` notarization:** Apple explicitly requires moving to `notarytool` or newer Xcode notarization flows.
- **Legacy UTI constant-heavy app code:** current planning should use `UTType` in Swift-facing logic.
</sota_updates>

## Validation Architecture

- **Wave 0 test harness:** create an Xcode project with a macOS app target and a unit test target before implementing association logic.
- **Automated unit coverage:** taxonomy resolution, language bucket expansion, curated editor ranking, and capability-state transitions should all be unit tested.
- **Adapter tests:** Launch Services and workspace wrappers should have mock-backed tests so behavior can be exercised without mutating the real machine.
- **Real-system probe:** add one manual or guarded integration path that can set and read back handlers for representative types like `.txt`, `.md`, and `.py` using throwaway targets or a dedicated smoke-test routine.
- **Pass condition for Phase 1:** at least one representative content type must complete a real write + readback cycle, and the system must surface partial-support mismatches as structured results.

<open_questions>
## Open Questions

1. **How far should Phase 1 go on real-machine mutation testing?**
   - What we know: the phase success criteria require a prototype association writer that can update and re-read representative text/source-code handlers.
   - What's unclear: whether that probe should live as a unit-test-adjacent integration target, a debug-only command, or a small in-app developer harness.
   - Recommendation: choose the least invasive harness that still gives deterministic manual verification; planning should not block on a polished UI for this.

2. **Should capability validation rely only on system declarations or also a curated override table?**
   - What we know: the user wants curated recommendations, and Apple’s ranking/declaration model depends on bundle metadata that can be incomplete in practice.
   - What's unclear: how many common editors need manual normalization on top of Launch Services before the discovery list feels correct.
   - Recommendation: plan for a built-in known-editor table with bundle identifiers and weights, but treat system eligibility as the baseline truth for whether an app appears at all.

3. **Which automated test style should the new project standardize on?**
   - What we know: XCTest is the lowest-risk path for `xcodebuild test`, while Swift Testing is more modern.
   - What's unclear: whether the project wants to adopt Swift Testing immediately or after the foundation is stable.
   - Recommendation: use XCTest in Phase 1 unless the executor can prove Swift Testing gives equal CI and tooling ergonomics with no extra setup cost.
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [Xcode support page](https://developer.apple.com/support/xcode/) — current stable and RC Xcode versions, supported macOS baselines, and Swift compiler versions
- [Signing Mac software with Developer ID](https://developer.apple.com/developer-id/) — Gatekeeper, hardened runtime, notarization, and `notarytool` migration requirements
- [Distributing software on macOS](https://developer.apple.com/macos/distribution/) — outside-App-Store distribution guidance and sandboxing comparison table
- [UTTypeSourceCode](https://developer.apple.com/documentation/uniformtypeidentifiers/uttypesourcecode) — confirms `public.source-code` conforms to text
- [UTType filename-extension initializer](https://developer.apple.com/documentation/uniformtypeidentifiers/uttypereference/init%28filenameextension%3A%29?language=objc) — dynamic undeclared-type behavior for unrecognized extensions
- [LSSetDefaultRoleHandlerForContentType](https://developer.apple.com/documentation/coreservices/1444955-lssetdefaultrolehandlerforconten?changes=_6&language=objc) — system API for setting default handlers by content type and role
- [NSWorkspace.urlsForApplications(toOpen:)](https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28toopen%3A%29-ualk?language=objc) — system discovery API for apps that can open a content type

### Secondary (MEDIUM confidence)
- [Core Foundation Keys reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html) — `LSItemContentTypes`, `CFBundleTypeRole`, and `LSHandlerRank` bundle-declaration details
- [Launch Services Programming Guide introduction](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCIntro/LSCIntro.html) — Launch Services capabilities and rationale
- [Launch Services Concepts](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html) — Launch Services database concepts and app registration behavior

### Tertiary (LOW confidence - needs validation)
- [Default Browser](https://sindresorhus.com/default-browser) — product reference for menu bar simplicity and note that much of the functionality would not be possible in the App Store because of sandboxing
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: macOS type resolution, app discovery, Launch Services mutation
- Ecosystem: Apple system frameworks only
- Patterns: domain-first modeling, thin adapters, post-write verification
- Pitfalls: partial support, dynamic UTTypes, misleading discovery results

**Confidence breakdown:**
- Standard stack: HIGH — grounded in Apple support and framework docs
- Architecture: MEDIUM-HIGH — strong fit for the phase, though exact harness shape is still open
- Pitfalls: MEDIUM — based on Apple concepts plus expected real-world editor bundle variance
- Code examples: MEDIUM-HIGH — API-level patterns are grounded in official docs, but full real-world behavior still needs probe validation

**Research date:** 2026-03-25
**Valid until:** 2026-04-24
</metadata>

---

*Phase: 01-discovery-association-core*
*Research completed: 2026-03-25*
*Ready for planning: yes*
