---
description: 再次删除 GitHub release/tag 并重新发布 v1.0-preview.1
date: 2026-03-31
status: completed
---

# Quick Task 260331-jwp Summary

- Deleted the existing GitHub prerelease and local/remote tag for `v1.0-preview.1`, leaving no release or tag behind before rebuild.
- Confirmed the project version still resolves to `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`; no source version bump was required for this rerun.
- Confirmed `origin/master` was already up to date at commit `122d2f9`, then rebuilt the preview artifact with `./Tools/Release/build-preview.sh`.
- Verified the exported app with the build script's `codesign --verify --deep --strict --verbose=2` check, confirmed `preview-manifest.txt` contains `tag=v1.0-preview.1`, and unzipped the archive into `/tmp/default-editor-switcher-preview-check/DefaultEditorSwitcher.app`.
- Published the recreated GitHub prerelease at `https://github.com/congbo/default-editor-switcher/releases/tag/v1.0-preview.1`.
- Added quick-task tracking artifacts in `.planning/quick/260331-jwp-github-release-tag-1-0-1-push-master-bui/` and logged the task in `.planning/STATE.md`.
