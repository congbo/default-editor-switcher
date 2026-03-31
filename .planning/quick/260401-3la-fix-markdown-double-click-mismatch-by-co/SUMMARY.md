# Quick Task 260401-3la

## Summary

Implemented the Launch Services role convergence fix for global text switching.

## Changes

- Batch global text mutations now write `all`, `viewer`, and `editor` roles per content type.
- Global text state now reflects opener semantics (`all -> viewer -> editor`) while retaining per-role handler details for verification.
- Menu and settings copy now describe the current default app instead of only the editor role.
- Switch feedback now includes role annotations when a specific Launch Services role is still mismatched or unsupported.

## Verification

- `xcodebuild test -scheme DefaultEditorSwitcher -only-testing:DefaultEditorSwitcherTests/LaunchServicesClientTests -only-testing:DefaultEditorSwitcherTests/GlobalTextStateServiceTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchCoordinatorTests -only-testing:DefaultEditorSwitcherTests/GlobalTextSwitchFeedbackFormatterTests -only-testing:DefaultEditorSwitcherTests/SettingsCopyFormatterTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`
