---
description: 再次删除 GitHub release/tag 并重新发布 v1.0-preview.1
date: 2026-03-30
status: completed
---

# Quick Task 260330-wp8 Summary

- Deleted the existing `v1.0-preview.1` GitHub prerelease plus the matching local and remote tag, then confirmed both release and tag lists were empty before rebuilding.
- Re-checked the Xcode build settings and confirmed the version inputs already remained at `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`, so no version file edit was needed.
- Rebuilt the preview artifact with `./Tools/Release/build-preview.sh`, producing a fresh `DefaultEditorSwitcher-v1.0-preview.1-macOS-Universal.zip` and `preview-manifest.txt`.
- Verified `preview-manifest.txt` still contains `tag=v1.0-preview.1` and unzipped the archive into `/tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app`.
- Republished the GitHub prerelease at `https://github.com/congbo/default-editor-switcher/releases/tag/v1.0-preview.1`, which now points at commit `6ebb9fc`.
- Added quick-task tracking artifacts in `.planning/quick/260330-wp8-github-release-tag-v1-0-preview-1-1-0-1-/` and logged the task in `.planning/STATE.md`.
