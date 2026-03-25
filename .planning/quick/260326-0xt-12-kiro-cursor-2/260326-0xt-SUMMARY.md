---
quick_id: 260326-0xt
description: 菜单栏下拉不显示扩展名列；下拉个数改为12；全局推荐里kiro排在Cursor之后；同步更新阶段2相关文档
completed: 2026-03-26
status: completed
verification: passed
commit: working-tree
---

# Quick Task 260326-0xt Summary

## Outcome

- Removed extension-preview feedback from the menu dropdown and replaced partial-failure copy with affected-count messaging.
- Increased the top-level recommended menu capacity from 8 to 12 items.
- Added `Kiro` (`dev.kiro.desktop`) to the curated recommended editor catalog immediately after `Cursor`.
- Updated Phase 2 context, UI contract, verification notes, and summary docs to reflect the current shipped behavior.

## Files Touched

- `App/Features/MenuBar/MenuBarViewModel.swift`
- `App/Support/KnownEditors.swift`
- `Tests/DefaultEditorSwitcherTests/MenuBarViewModelTests.swift`
- `Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift`
- `.planning/phases/02-menu-bar-global-switch/02-CONTEXT.md`
- `.planning/phases/02-menu-bar-global-switch/02-UI-SPEC.md`
- `.planning/phases/02-menu-bar-global-switch/02-VERIFICATION.md`
- `.planning/phases/02-menu-bar-global-switch/02-03-SUMMARY.md`

## Verification

`xcodebuild clean test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests -only-testing:DefaultEditorSwitcherTests/EditorRankingPolicyTests`

Passed on 2026-03-26.

## Notes

- No atomic git commit was created for this quick task because the repository already had unrelated in-progress changes in the working tree.
