# Quick Task 260330-ugm Summary

## Outcome

Filtered workspace-discovered editor candidates against real bundle existence before ranking them, so stale Launch Services registrations no longer occupy recommended menu slots.

## Changes

- Added `ApplicationBundleExistenceChecking` and a file-system-backed default checker in workspace discovery.
- Excluded nonexistent application bundle URLs before converting them into `EditorCandidate`s.
- Added a regression test for missing app bundles and updated existing workspace discovery tests to declare which fake bundle URLs should count as installed.

## Verification

- `xcodebuild test -project DefaultEditorSwitcher.xcodeproj -scheme DefaultEditorSwitcher -destination 'platform=macOS' -only-testing:DefaultEditorSwitcherTests/WorkspaceDiscoveryTests -only-testing:DefaultEditorSwitcherTests/MenuBarViewModelTests`
