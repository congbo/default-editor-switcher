---
description: fix Xcode shown unavailable in settings
date: 2026-03-26
status: completed
---

# Quick Task 260326-hh7 Summary

- Confirmed the bug was in settings formatting rather than app discovery: `NSWorkspace` still resolves `/Applications/Xcode.app`, but the settings list only treated `.full` candidates as available and downgraded everything else to "Currently unavailable on this Mac".
- Updated `SettingsCopyFormatter` so any discovered editor remains available in the recommended list, with `.full` entries keeping menu-placement copy and `.partial` / `.unverified` entries showing capability-specific detail instead of the unavailable message.
- Added formatter assertions covering partial and unverified recommended editors, including the Xcode case, and verified the change with `xcodebuild test -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/SettingsCopyFormatterTests`.
