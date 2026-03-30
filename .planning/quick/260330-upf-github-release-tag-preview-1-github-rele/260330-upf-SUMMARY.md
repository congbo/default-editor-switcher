---
description: 重置 GitHub Release/Tag 并重新发布 Preview 1
date: 2026-03-30
status: completed
---

# Quick Task 260330-upf Summary

- Deleted all existing GitHub prereleases and local/remote tags so `v1.0-preview.1` could be recreated without conflicts.
- Reset `CURRENT_PROJECT_VERSION` from `3` to `1` in `DefaultEditorSwitcher.xcodeproj/project.pbxproj`, keeping `MARKETING_VERSION = 1.0`, and pushed release-prep commit `d3f0882` (`chore(release): reset preview version to v1.0-preview.1`) to `origin/master`.
- Built the preview artifact with `./Tools/Release/build-preview.sh`, producing `DefaultEditorSwitcher-v1.0-preview.1-macOS-Universal.zip` and a manifest tagged `v1.0-preview.1`.
- Verified the exported app with the build script's `codesign --verify --deep --strict --verbose=2` check, confirmed `preview-manifest.txt` contains `tag=v1.0-preview.1`, and unzipped the archive into `/tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app`.
- Published the new GitHub prerelease at `https://github.com/congbo/default-editor-switcher/releases/tag/v1.0-preview.1`.
- Added quick-task tracking artifacts in `.planning/quick/260330-upf-github-release-tag-preview-1-github-rele/` and logged the task in `.planning/STATE.md`.
