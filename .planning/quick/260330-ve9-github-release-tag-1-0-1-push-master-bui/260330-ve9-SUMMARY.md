---
description: 再次删除 GitHub release/tag，保持版本号 1.0 (1)，重新发布 v1.0-preview.1
date: 2026-03-30
status: completed
---

# Quick Task 260330-ve9 Summary

- Deleted the existing GitHub prerelease `v1.0-preview.1` and removed the matching local and remote tag so the release could be recreated from the current code state.
- Confirmed the project build settings remain at `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`, then verified `master` was already fully pushed at commit `4b89281`.
- Rebuilt the preview artifact with `./Tools/Release/build-preview.sh`, producing `DefaultEditorSwitcher-v1.0-preview.1-macOS-Universal.zip` and a manifest tagged `v1.0-preview.1`.
- Verified the exported app through the build script's `codesign --verify --deep --strict --verbose=2` check, confirmed `preview-manifest.txt` contains `tag=v1.0-preview.1`, and unzipped the archive into `/tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app`.
- Republished the GitHub prerelease at `https://github.com/congbo/default-editor-switcher/releases/tag/v1.0-preview.1`.
- Added quick-task tracking artifacts in `.planning/quick/260330-ve9-github-release-tag-1-0-1-push-master-bui/` and logged the task in `.planning/STATE.md`.
