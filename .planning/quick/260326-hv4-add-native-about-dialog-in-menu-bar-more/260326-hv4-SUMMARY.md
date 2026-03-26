---
description: add native about dialog in menu bar more menu
date: 2026-03-26
status: completed
---

# Quick Task 260326-hv4 Summary

- Added an About action to the menu bar "More" submenu and wired it to the native macOS standard About panel instead of a custom window.
- Configured the About panel credits area with a centered, clickable GitHub project link: `https://github.com/congbo/default-editor-switcher`.
- Added focused tests for the localized About menu title and the About panel credits configuration, then verified the change with `xcodebuild test -project DefaultEditorSwitcher.xcodeproj -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`.
