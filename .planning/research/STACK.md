# Stack Research

**Domain:** macOS developer utility for switching default file editors
**Researched:** 2026-03-25
**Confidence:** MEDIUM-HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Xcode | 26.3 stable | Build, sign, archive, and notarize the app | Apple’s current stable toolchain is the safest path for a direct-distributed macOS product |
| Swift | 6.3 compiler, Swift 6/5 mode as needed | Main implementation language | Native access to AppKit, CoreServices, and modern SwiftUI scenes with the lowest integration friction |
| SwiftUI | macOS app scene APIs in current Xcode 26 line | Main window, settings views, lightweight app shell | Fastest way to build a native settings UI and menu bar experience without carrying AppKit window code everywhere |
| AppKit | macOS SDK in current Xcode 26 line | App discovery, icons, menu bar edge cases, workspace integration | `NSWorkspace` and related APIs remain central for app URLs, icons, and macOS utility behavior |
| UniformTypeIdentifiers | System framework | Map extensions and language buckets to content types | Gives a principled type model instead of hard-coding only raw extensions; critical for grouping source-code and text families |
| Launch Services / CoreServices | System framework | Read and write default editor associations | The file-association mutation path lives here; this is the core capability the product exists to wrap |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UserDefaults + JSON snapshot files | System APIs | Persist preferences, last-used editor, and restorable snapshots | Use in v1 for lightweight local persistence without introducing a database |
| ServiceManagement | System framework | Launch at login | Use only if “start with macOS” becomes a v1.x requirement |
| KeyboardShortcuts | Optional third-party package, verify at implementation time | User-configurable global hotkey | Use only if the built-in menu bar click flow is not sufficient and a stable shortcut UX is required |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode Instruments | Performance and launch profiling | Useful mainly to keep menu bar idle CPU/memory near zero |
| `log stream` / Console | Observe Launch Services and signing behavior | Important when debugging association updates and post-notarization builds |
| `codesign`, `spctl`, `notarytool` | Verify direct-distribution builds | Required for release hardening outside the Mac App Store |

## Installation

```bash
# Core stack is Apple-native.
# No third-party package is required for the MVP.

# Optional package if a custom global hotkey is added:
# xcodebuild -resolvePackageDependencies
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftUI + focused AppKit bridges | Full AppKit app | Use full AppKit only if SwiftUI scene limitations block critical menu bar or settings-window behavior |
| Direct distribution with Developer ID + notarization | Mac App Store distribution | Use only if future product strategy prioritizes App Store discovery over association-changing capability flexibility |
| Apple-native persistence | SQLite / SwiftData | Use a database only if rules, profiles, history, or sync become materially more complex |
| Direct Launch Services mutation | “Picker app” interception architecture like Velja | Use interception only if the product expands into routing logic instead of directly changing system defaults |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron or other web-shell runtime for MVP | Too much memory/process overhead for a tiny menu bar utility and weaker native integration around Launch Services | Native Swift app |
| Mac App Store as the primary release target | The closest analogous product explicitly notes sandboxing would block much of the functionality, and Apple says sandboxing is required in the Mac App Store but only recommended outside it | Direct distribution with Developer ID + notarization |
| Extension-only mapping without UTType normalization | Leads to brittle behavior across `.ts`, `.tsx`, `.md`, custom extensions, and editor capability checks | Model rules as extension + resolved content type where possible |

## Stack Patterns by Variant

**If the MVP stays intentionally small:**
- Use a single app target with `MenuBarExtra`, one settings window, and a compact service layer.
- Because the app is local-only and does not need plugin architecture or sync.

**If release validation proves Launch Services writes are flaky on some types:**
- Add a verification layer that re-reads the preferred handler after each batch write and offers restore/retry.
- Because correctness matters more than raw speed for destructive preference changes.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Xcode 26.3 | Swift 6.3, macOS 26.2 SDK | Current stable toolchain from Apple support pages at research time |
| Deployment target recommendation | macOS 14+ | Inference: modern enough for a polished native utility while avoiding legacy compatibility drag |

## Sources

- https://developer.apple.com/support/xcode/ — current stable Xcode line and Swift compiler information
- https://developer.apple.com/documentation/swiftui/menubarextra — native menu bar scene support
- https://developer.apple.com/documentation/appkit/nsworkspace/urlsforapplications%28toopen%3A%29-ualk?language=objc — discover apps that can open a content type
- https://developer.apple.com/documentation/coreservices/1444955-lssetdefaultrolehandlerforconten?changes=_6&language=objc — Launch Services API for setting default handler by content type
- https://developer.apple.com/documentation/uniformtypeidentifiers/uttypesourcecode — `public.source-code` conforms to text
- https://developer.apple.com/macos/distribution/ — distribution outside the Mac App Store and sandboxing guidance
- https://developer.apple.com/developer-id/ — Developer ID signing and notarization path
- https://sindresorhus.com/default-browser — analogous product boundary and App Store limitation note

---
*Stack research for: macOS developer utility for switching default file editors*
*Researched: 2026-03-25*
