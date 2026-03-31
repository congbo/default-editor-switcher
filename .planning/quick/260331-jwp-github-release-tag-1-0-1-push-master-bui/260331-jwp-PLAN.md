---
description: 再次删除 GitHub release/tag 并重新发布 v1.0-preview.1
date: 2026-03-31
status: completed
---

# Quick Task 260331-jwp Plan

1. Delete the existing GitHub prerelease and local/remote tag for `v1.0-preview.1` so the preview can be recreated cleanly.
2. Confirm the project version remains `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`, then push the current `master` state to GitHub.
3. Rebuild the preview artifact, verify the manifest and archive still resolve to `v1.0-preview.1`, publish the new GitHub prerelease, and record the task in `.planning/quick` and `.planning/STATE.md`.
