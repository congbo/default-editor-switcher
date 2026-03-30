---
description: 再次删除 GitHub release/tag 并重新发布 v1.0-preview.1
date: 2026-03-30
status: completed
---

# Quick Task 260330-wzu Summary

- Deleted the existing `v1.0-preview.1` GitHub prerelease and removed the matching local and remote tags so the preview could be recreated cleanly.
- Kept `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`, then pushed the current working-tree changes plus release plan as commit `4275b11` (`chore(release): republish v1.0-preview.1`) to `origin/master`.
- Rebuilt the preview artifact with `./Tools/Release/build-preview.sh`, producing `DefaultEditorSwitcher-v1.0-preview.1-macOS-Universal.zip` and a manifest tagged `v1.0-preview.1`.
- Verified the exported app with the build script's `codesign --verify --deep --strict --verbose=2` check, confirmed `preview-manifest.txt` contains `tag=v1.0-preview.1`, and unzipped the archive into `/tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app`.
- Published the refreshed GitHub prerelease at `https://github.com/congbo/default-editor-switcher/releases/tag/v1.0-preview.1`.
- Added quick-task tracking artifacts in `.planning/quick/260330-wzu-github-release-tag-v1-0-preview-1-1-0-1-/` and logged the task in `.planning/STATE.md`.
