---
description: 设置页状态卡片重构与菜单栏联动刷新：修复设置页未随菜单栏切换刷新，合并异常与日志为单一状态卡片，并优化通用页布局
date: 2026-03-26
status: completed
---

# Quick Task 260326-8ix Summary

- Added shared `currentState` and `availableEditors` publishing to `MenuBarViewModel`, and rewired `SettingsWindowView` to read those live values instead of keeping a one-time local snapshot, so the settings window now updates immediately after menu-bar switches.
- Reworked settings copy formatting into a single status snapshot that merges current distribution, unassigned extensions, and recent switch results; the General section now renders that data as one card with neutral status labels and cleaner spacing.
- Updated localized strings and unit coverage for the new snapshot model and refresh behavior; verification passed with `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS'`.
