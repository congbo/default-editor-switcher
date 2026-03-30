---
description: 重置 GitHub Release/Tag 并重新发布 Preview 1
date: 2026-03-30
status: completed
---

# Quick Task 260330-upf Plan

1. Delete all existing GitHub releases plus local and remote git tags so `v1.0-preview.1` can be recreated cleanly.
2. Reset `CURRENT_PROJECT_VERSION` from `3` to `1` while keeping `MARKETING_VERSION = 1.0`, then record the quick-task artifacts in `.planning/quick` and `.planning/STATE.md`.
3. Commit the release reset, push `master`, rebuild the preview artifact, verify the manifest and archive resolve to `v1.0-preview.1`, and publish the new GitHub prerelease.
