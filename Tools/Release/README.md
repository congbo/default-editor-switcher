# Release Workflow

This directory contains two distribution tracks for `DefaultEditorSwitcher`:

- Formal release: Developer ID signed, notarized, stapled, and suitable for direct-download shipping.
- Preview release: ad-hoc signed, not notarized, and suitable for local evaluation or clearly labeled GitHub prereleases.

## Choose The Right Track

- Use `./Tools/Release/build-release.sh` for formal public releases.
- Use `./Tools/Release/build-preview.sh` for self-testing and preview distribution when Developer ID / notarization credentials are unavailable.
- Use `./Tools/Release/publish-preview.sh` only for GitHub prereleases. Do not mix preview assets into formal notarized releases.

## Required Environment Variables

- `DEVELOPMENT_TEAM_ID` — Apple Developer Team ID used for the archive/export step
- `CODE_SIGN_IDENTITY` — signing identity passed to `xcodebuild`, typically `Developer ID Application`
- `NOTARY_PROFILE` — keychain profile name created with `xcrun notarytool store-credentials`

## Build A Release Artifact

Run the single entrypoint from the repository root:

```bash
./Tools/Release/build-release.sh
```

The script archives, exports, zips, notarizes, staples, and re-zips the app, then writes release metadata to `build/release/release-manifest.txt`.

## Build A Preview Artifact

Run the preview entrypoint from the repository root:

```bash
./Tools/Release/build-preview.sh
```

The preview script:

- reads `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from the Xcode Release build settings
- builds the app in `Release`
- copies the app into `build/preview/exported/`
- applies ad-hoc signing
- zips the app as `build/preview/DefaultEditorSwitcher-v<version>-preview.<build>-macOS.zip`
- writes `build/preview/preview-manifest.txt`

Expected preview outputs:

- `build/preview/exported/DefaultEditorSwitcher.app`
- `build/preview/DefaultEditorSwitcher-v<version>-preview.<build>-macOS.zip`
- `build/preview/preview-manifest.txt`

## Verify The Exported Artifact

Run artifact verification against the exported app bundle and final zip:

```bash
./Tools/Release/verify-artifact.sh \
  build/release/exported/DefaultEditorSwitcher.app \
  build/release/DefaultEditorSwitcher-macOS.zip
```

`verify-artifact.sh` checks:

- `codesign --verify --deep --strict --verbose=2`
- `spctl -a -vv --type execute`
- `xcrun stapler validate`
- `xcrun notarytool log` when `submission_id` is present in `build/release/release-manifest.txt`

## Verify A Preview Artifact Locally

Preview builds are not notarized, so local verification is limited to build integrity and ad-hoc signing:

```bash
codesign --verify --deep --strict --verbose=2 build/preview/exported/DefaultEditorSwitcher.app
codesign -dv --verbose=4 build/preview/exported/DefaultEditorSwitcher.app 2>&1 | rg "Signature=adhoc"
ditto -x -k build/preview/DefaultEditorSwitcher-v<version>-preview.<build>-macOS.zip /tmp/default-editor-switcher-preview-check
open /tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app
```

If Finder warns on first launch, use right-click `Open`.

## Publish A Preview Prerelease

After building a preview artifact, publish it to GitHub as a prerelease:

```bash
./Tools/Release/publish-preview.sh
```

For local validation without creating a GitHub release:

```bash
./Tools/Release/publish-preview.sh --dry-run
```

The prerelease notes explicitly state that the uploaded build is:

- a preview
- ad-hoc signed
- not notarized
- likely to trigger a macOS warning on first launch

## Expected Outputs

After a successful run, `build/release/` contains:

- `DefaultEditorSwitcher.xcarchive`
- `exported/DefaultEditorSwitcher.app`
- `DefaultEditorSwitcher-macOS.zip`
- `release-manifest.txt`

## Credential Setup

Create the notarization profile once on the release machine:

```bash
xcrun notarytool store-credentials <profile-name>
```

Then export:

```bash
export DEVELOPMENT_TEAM_ID="<team-id>"
export CODE_SIGN_IDENTITY="Developer ID Application"
export NOTARY_PROFILE="<profile-name>"
```

## Tester Notes For Preview Builds

- Preview builds are for evaluation, not trusted distribution.
- Gatekeeper may warn because preview builds are ad-hoc signed and not notarized.
- First launch may require right-click `Open`.
- Use the formal release flow when you need an installable build for broad public distribution.
