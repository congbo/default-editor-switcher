# Phase 4: Release Hardening - Research

**Researched:** 2026-03-26
**Domain:** direct-download macOS release packaging, notarization, install verification, and actionable association-failure UX
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from roadmap and context)

### Locked Decisions
- Phase 4 ships the current app as a trustworthy direct-download macOS utility; it does not expand product scope beyond release readiness and clearer failure handling.
- Distribution must target Developer ID signing plus notarization, not Mac App Store packaging or a sandbox-first redesign.
- Release validation must cover the shipped artifact outside Xcode, including Gatekeeper acceptance, launchability, and the core editor-switch flow.
- Association-write failures must stay grounded in the existing verification model: `mismatched`, `unsupportedTarget`, and `writeFailed`.
- Failure UI must tell the user what scope failed and what to do next instead of surfacing raw diagnostics only.

### the agent's Discretion
- The install wrapper can be a notarized `.zip` containing `DefaultEditorSwitcher.app` as long as the workflow is reproducible and easy to validate on a clean machine.
- Release automation can live in shell scripts under `Tools/Release/` with documented environment variables instead of introducing CI before the local release path is stable.
- Failure feedback can appear in the menu bar flow, the settings window, or both, provided the fast-switch workflow remains menu-first and the recovery action is obvious.

### Deferred Ideas (OUT OF SCOPE)
- Mac App Store compatibility, sandbox remapping, and helper-app packaging variants
- Snapshot restore and baseline restore UX beyond the current release-hardening scope
- Per-language rule management, custom extension CRUD, and any new routing features

</user_constraints>

<research_summary>
## Summary

Phase 4 should turn the current debug-friendly macOS app into a release-ready product with two tightly connected deliverables: a repeatable signed-and-notarized artifact pipeline, and product-owned failure feedback that explains partial or failed Launch Services writes. The repository already has most of the domain ingredients. The missing work is packaging discipline and a presentation layer that turns `GlobalTextSwitchReport` plus `AssociationVerificationResult` into actionable UI copy.

The least risky v1 release shape is a notarized `.zip` wrapping `DefaultEditorSwitcher.app`. That keeps the pipeline Apple-native, avoids introducing a DMG builder dependency, and is easy to validate with `codesign`, `spctl`, `notarytool`, `stapler`, and an unzip/install flow that mirrors direct download. The project currently has `Release` configurations with signing disabled, so the release-hardening plan must explicitly enable app-target signing, hardened runtime, archive/export settings, and an operator script that fails fast when required credentials are missing.

The app-side hardening should build on existing verified outcomes instead of inventing a second error taxonomy. `LaunchServicesAssociationVerifier` already distinguishes `mismatched`, `unsupportedTarget`, and `writeFailed`, while `GlobalTextSwitchCoordinator` already returns a bounded set of sample failures. Phase 4 should enrich that report with human-facing scope labels and surface a concise feedback block in the menu bar flow that says what failed, whether the failure was partial or complete, and how to recover. The recovery path should always stay concrete: retry from the signed release build, pick a different editor for unsupported scopes, or open `Settings...` for follow-up guidance.

**Primary recommendation:** implement Phase 4 as two sequential plans. First, make release packaging deterministic with archive/export/notarize/staple/verification scripts and project signing settings. Second, harden the user-facing failure summary and add installed-artifact validation so the shipped app is trustworthy both operationally and experientially.
</research_summary>

<standard_stack>
## Standard Stack

The established libraries and tools for this phase:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Xcode / `xcodebuild` | Xcode 26.3 stable | Archive and export the app with Release settings | Apple-native archive/export flow matches the direct-download requirement |
| `codesign` | macOS system tool | Verify signature, hardened runtime, and deep code-sign integrity | Required to prove the release artifact is truly signed |
| `xcrun notarytool` | Xcode-bundled | Submit the zipped artifact to Apple notarization and wait for acceptance | Current Apple-first notarization path for direct distribution |
| `xcrun stapler` | Xcode-bundled | Staple notarization tickets to the exported app | Makes offline Gatekeeper validation practical |
| `spctl` | macOS system tool | Validate Gatekeeper acceptance of the shipped app | Required by the phase success criteria |
| SwiftUI + AppKit | Current app stack | Surface release-safe failure feedback in the menu bar flow | Keeps hardening work aligned with the shipped UI surface |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Shell scripts under `Tools/Release/` | POSIX shell / zsh-compatible | Wrap archive/export/notarize/staple/verify commands into a reproducible local workflow | Use for all operator-facing release steps in v1 |
| `Localizable.xcstrings` plus `AppTextLocalizing` | Existing app infrastructure | Localize release-facing failure copy and recovery actions | Use for any user-visible failure text added in Phase 4 |
| XCTest | Existing target | Guard feedback formatting and menu-bar presentation regressions | Use for all deterministic copy and state derivation checks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Notarized `.zip` artifact | DMG-based installer | DMG can look more polished, but adds tooling and packaging complexity that the repo does not yet need |
| Local shell scripts | CI-first release automation | CI can come later, but Phase 4 first needs a trusted local release path with explicit operator evidence |
| Reusing verification statuses | A new release-only error enum | A new enum would drift from the actual write/verify truth source and make failures harder to reason about |

**Installation:**
```bash
# No new package manager dependency is required.
# Release operators need Xcode CLT plus an installed Developer ID certificate.
xcodebuild -version
xcrun notarytool --help
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Pattern 1: One release entrypoint, many verifiers
**What:** Put archive, export, zip, notarize, staple, and artifact checks behind a single `Tools/Release/build-release.sh` entrypoint, then delegate post-build assertions to dedicated verification scripts.
**When to use:** For every real release and every dry run that prepares a shipping artifact.
**Why:** Operators should not manually remember a fragile sequence of Xcode and notarization commands.

### Pattern 2: Signing configuration belongs to the app target, credentials stay external
**What:** Commit project settings that enable Release signing and hardened runtime for the app target, but keep team ID, certificate resolution, and notary profile in environment variables or local keychain profiles.
**When to use:** For all release archives.
**Why:** The repo needs deterministic build behavior without hard-coding secrets or user-specific certificate names.

### Pattern 3: Failure presentation derives from `GlobalTextSwitchReport`
**What:** Build a formatter or presentation model that consumes the existing aggregate report plus sample failures and produces localized headline/detail/recovery copy.
**When to use:** After every global-switch attempt that does not fully match.
**Why:** The report already contains the hard truth; the missing layer is user-facing explanation.

### Pattern 4: Installed-artifact validation is separate from unit tests
**What:** Keep XCTest focused on deterministic formatting and state transitions, then add shell-based verification for `codesign`, `spctl`, app launch, and clean-install steps.
**When to use:** For every release candidate.
**Why:** A debug-run unit suite cannot prove direct-download install trust.

### Anti-Patterns to Avoid
- **Leaving `CODE_SIGNING_ALLOWED = NO` for the app Release configuration:** that guarantees the archive/export path cannot prove the shipping configuration.
- **Hard-coding Apple ID credentials in the repository:** notarization should read a keychain profile or environment variables only.
- **Showing only raw UTType identifiers or OSStatus values without explanation:** they can be included as supporting detail, but the first line must tell the user what failed and how to recover.
- **Burying release validation steps in ad hoc notes:** the workflow should leave behind executable scripts and a short checklist, not memory-dependent tribal knowledge.
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look easy but already have better building blocks:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release packaging | A manual Xcode Organizer-only flow | `xcodebuild archive`, `xcodebuild -exportArchive`, `notarytool`, `stapler`, `spctl` scripts | Scriptable steps leave reproducible evidence and reduce operator error |
| Failure messaging | A new ad hoc status model in SwiftUI | `GlobalTextSwitchReport` plus localized formatting helpers | Keeps UI feedback aligned with the write-verification truth source |
| Recovery routing | A new window or modal-heavy flow | Existing `Settings...` window plus clear menu feedback | Preserves the app's tiny utility posture while still giving users a path forward |
| Clean-machine validation | Debug-build smoke checks only | Signed artifact unzip/install/launch flow with `spctl` and `codesign` | Phase 4 is specifically about release behavior, not debug comfort |

**Key insight:** Phase 4 is not primarily a UI phase or a CI phase; it is a trust phase. The release artifact and the failure copy both need to be concrete enough that a user can trust what the app says and what macOS will accept.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: The archive exports, but the app target is still effectively unsigned
**What goes wrong:** The release script completes, but the app cannot pass Gatekeeper or codesign verification because Release signing is still disabled in the project.
**Why it happens:** Current Release build settings disable signing entirely, which is fine for local builds but invalid for shipping.
**How to avoid:** Explicitly enable signing and hardened runtime for the `DefaultEditorSwitcher` app target while keeping credentials external.
**Warning signs:** `codesign --verify` or `spctl -a -vv` fails on the exported app even though `xcodebuild archive` completed.

### Pitfall 2: The notarization workflow is technically correct but hard to rerun
**What goes wrong:** Only one person knows the exact export path, zip command, or `notarytool` invocation, and the release process fails on the next machine.
**Why it happens:** Steps are copied from shell history instead of codified.
**How to avoid:** Create a single release script with fixed directory conventions, required environment variables, and failure-fast messaging.
**Warning signs:** Operators edit paths by hand or forget whether stapling happens before or after rezipping.

### Pitfall 3: Partial switch failures still look like silent success
**What goes wrong:** The requested editor becomes current for some types, but the menu offers no actionable context for the remaining mismatches or unsupported scopes.
**Why it happens:** `lastSwitchReport` is stored for tests but not turned into user-facing copy.
**How to avoid:** Publish a localized failure presentation whenever `affectedCount > 0` and show up to three concrete failed scopes plus a recovery action.
**Warning signs:** Tests assert that the latest report exists, but the user sees only the changed current editor with no explanation.

### Pitfall 4: Clean-machine release validation stops at signature checks
**What goes wrong:** The signed and notarized app passes `codesign` and `spctl`, but the first-launch path or editor-switch flow still breaks outside Xcode.
**Why it happens:** Validation focuses only on packaging, not product behavior.
**How to avoid:** Add an installed-artifact verification script and a checklist that includes launch, menu interaction, and one successful plus one failure-mode switch attempt.
**Warning signs:** Release notes say “notarized” but there is no evidence the shipped app was opened and exercised after install.
</common_pitfalls>

<code_examples>
## Code Examples

Repository-aligned patterns that should guide this phase:

### Release pipeline shell sequence
```bash
xcodebuild archive \
  -scheme DefaultEditorSwitcher \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM_ID" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  CODE_SIGN_STYLE=Manual \
  ENABLE_HARDENED_RUNTIME=YES

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist Tools/Release/export-options.plist

ditto -c -k --keepParent "$EXPORT_DIR/DefaultEditorSwitcher.app" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$EXPORT_DIR/DefaultEditorSwitcher.app"
spctl -a -vv --type execute "$EXPORT_DIR/DefaultEditorSwitcher.app"
```

### Failure feedback from existing report data
```swift
if report.affectedCount > 0 {
    let headline = localizer.formattedString(
        "%d text types could not switch to %@.",
        report.affectedCount,
        requestedEditorName
    )
}
```

### Recovery action remains the existing settings window
```swift
Button(localizer.string("Open Settings for Recovery")) {
    NSApp.activate(ignoringOtherApps: true)
    openWindow(id: MenuBarViewModel.settingsWindowID)
}
```
</code_examples>

<implementation_notes>
## Implementation Notes

- Prefer `Tools/Release/` for all release scripts, export options, and operator docs so the release workflow stays close to the existing `Tools/AssociationProbe` pattern.
- The app target is the only target that needs Release signing/hardened runtime; test and probe targets can stay unsigned.
- `build-release.sh` should require a small explicit contract such as `DEVELOPMENT_TEAM_ID`, `CODE_SIGN_IDENTITY`, and `NOTARY_PROFILE`, then fail with a readable message if any are absent.
- The release script should create a deterministic output directory such as `build/release/` containing the archive, exported app, notarized zip, and a short manifest of verification results.
- Failure copy should prefer filename-extension examples or human labels over raw UTType identifiers when possible, but it can fall back to the identifier when no friendlier label is available.
- A successful switch should clear stale failure feedback so the menu does not keep showing outdated warnings.
- The clean-machine checklist should validate both a success path and a controlled failure path so DIST-01 and DIST-02 are proven together.
</implementation_notes>

## Validation Architecture

- **Wave 0 test harness:** the existing XCTest target plus shell syntax validation are sufficient; no new framework is required.
- **Release tooling coverage:** validate `Tools/Release/build-release.sh`, `Tools/Release/verify-artifact.sh`, and any installed-app verification script with `bash -n`, `plutil -lint`, and `rg` assertions for the required `xcodebuild`, `notarytool`, `stapler`, `codesign`, and `spctl` commands.
- **Failure-feedback coverage:** add tests proving the app publishes a localized recovery summary when `GlobalTextSwitchReport.affectedCount > 0`, includes the affected scope labels, and clears the warning on a later full-success report.
- **Menu integration coverage:** add tests proving the recovery action still targets `settings-window` and that the menu exposes the new recovery affordance only when the latest report includes failures.
- **Manual verification:** run the release build script with real credentials, unzip and move the notarized app into `/Applications`, verify Gatekeeper acceptance with `spctl`, launch the installed app outside Xcode, switch to a fully supported editor to confirm success, then trigger or simulate a partial failure and confirm the menu shows scope-specific recovery guidance.
- **Pass condition for Phase 4:** a notarized direct-download artifact is reproducible from repo scripts, Gatekeeper accepts it, the installed app launches and performs the core switch flow, and any partial/full association-write failure produces user-facing recovery guidance tied to the affected scope.
