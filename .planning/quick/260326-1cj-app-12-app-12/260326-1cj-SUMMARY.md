---
quick_id: 260326-1cj
description: 修正菜单栏一级下拉的app数量补齐逻辑，确保不足12个推荐项时由其他可选app补满到12个
completed: 2026-03-26
status: completed
verification: passed
commit: working-tree
---

# Quick Task 260326-1cj Summary

## Outcome

- Fixed the first-level menu so it backfills with other fully eligible apps when the curated recommendation list is shorter than 12 installed choices.
- Preserved the existing top-level cap at 12 rows, including the current-editor injection path.
- Updated Phase 2 docs and state tracking so they describe 12 visible app choices rather than 12 curated recommendations only.

## Files Touched

- `App/Features/MenuBar/MenuBarViewModel.swift`
- `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift`
- `.planning/phases/02-menu-bar-global-switch/02-CONTEXT.md`
- `.planning/phases/02-menu-bar-global-switch/02-UI-SPEC.md`
- `.planning/phases/02-menu-bar-global-switch/02-VERIFICATION.md`
- `.planning/STATE.md`

## Verification

`xcodebuild clean test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests -only-testing:DefaultEditorSwitcherTests/EditorRankingPolicyTests`

Passed on 2026-03-26.

## Notes

- No atomic git commit was created for this quick task because the repository already had unrelated in-progress changes in the working tree.
