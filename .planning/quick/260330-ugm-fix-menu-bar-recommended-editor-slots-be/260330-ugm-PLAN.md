# Quick Task 260330-ugm: Fix menu bar recommended editor slots being consumed by uninstalled apps returned from stale Launch Services registrations

## Goal

Prevent menu bar recommended editor slots from being occupied by apps that are no longer installed but still appear in Launch Services lookup results.

## Plan

1. Inspect the app discovery pipeline and add a guard so nonexistent application bundle URLs are excluded before ranking.
2. Add a regression test covering stale Launch Services registrations returning missing app paths.
3. Run focused tests for workspace discovery and menu bar presentation to confirm the shortlist only includes installed editors.
