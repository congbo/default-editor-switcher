---
quick_id: 260326-1fr
description: 调整非全局推荐 app 的默认排序，按支持的文本扩展名数量降序排列
completed: 2026-03-26
status: completed
verification: passed
commit: working-tree
---

# Quick Task 260326-1fr Summary

## Outcome

- Preserved the curated recommendation block at the front of the global menu, including the fixed `Cursor` -> `Kiro` ordering.
- Added support-count derivation for non-curated apps based on declared developer-text filename extensions and used it as the default global-menu tie-breaker.
- Kept capability classification unchanged while extending bundle metadata parsing to account for declared filename extensions.

## Files Touched

- `App/Domain/Editors/EditorCandidate.swift`
- `App/Domain/Editors/EditorRankingPolicy.swift`
- `App/Infrastructure/Workspace/BundleDocumentTypeReader.swift`
- `App/Infrastructure/Workspace/WorkspaceAppDiscovery.swift`
- `Tests/DefaultEditorSwitcherTests/EditorRankingPolicyTests.swift`
- `Tests/DefaultEditorSwitcherTests/WorkspaceDiscoveryTests.swift`
- `.planning/phases/02-menu-bar-global-switch/02-CONTEXT.md`
- `.planning/phases/02-menu-bar-global-switch/02-UI-SPEC.md`
- `.planning/phases/02-menu-bar-global-switch/02-VERIFICATION.md`
- `.planning/STATE.md`

## Verification

`xcodebuild clean test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/WorkspaceDiscoveryTests -only-testing:DefaultEditorSwitcherTests/EditorRankingPolicyTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`

Passed on 2026-03-26.

## Notes

- No atomic git commit was created for this quick task because the repository already had unrelated in-progress changes in the working tree.
