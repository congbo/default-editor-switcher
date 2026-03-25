---
description: Add preview build packaging and GitHub prerelease publishing for ad-hoc signed release artifacts
date: 2026-03-26
status: completed
---

# Quick Task 260326-7cf Summary

- Added `Tools/Release/build-preview.sh` to build a Release app without Developer ID credentials, ad-hoc sign it, version the output from Xcode build settings, and emit `build/preview/preview-manifest.txt`.
- Added `Tools/Release/publish-preview.sh` to create or update a GitHub prerelease from the preview manifest, upload the preview zip plus manifest, and support `--dry-run` validation without publishing.
- Expanded `Tools/Release/README.md` so the preview and formal release tracks are explicitly separated, including local preview verification commands and tester guidance for macOS first-launch warnings.
