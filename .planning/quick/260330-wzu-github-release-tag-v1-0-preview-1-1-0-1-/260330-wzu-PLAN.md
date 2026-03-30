---
description: 再次删除 GitHub release/tag 并重新发布 v1.0-preview.1
date: 2026-03-30
status: completed
---

# Quick Task 260330-wzu Plan

1. Delete the existing `v1.0-preview.1` GitHub prerelease plus local and remote tags so the preview can be recreated cleanly.
2. Keep `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`, and include the current working-tree changes as the new release baseline.
3. Commit and push the current changes, rebuild the preview artifact, verify the manifest and archive still resolve to `v1.0-preview.1`, publish the prerelease again, and record the task in `.planning/STATE.md`.
