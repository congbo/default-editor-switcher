---
quick_id: 260326-8jz
description: Redraw the app icon in a minimal style and aggressively reduce packaged icon asset sizes
completed: 2026-03-26
status: completed
verification: partial
commit: working-tree
---

# Quick Task 260326-8jz Summary

## Outcome

- Replaced the previous illustrated icon with a minimal 3-color concept: graphite rounded-square body, cyan editor panel outlines, and a white swap glyph inside a cyan center badge.
- Re-generated the full macOS `AppIcon.appiconset` without changing the asset catalog structure or Xcode wiring.
- Switched the export pipeline to palette/indexed PNG output so the icon resources are dramatically smaller while preserving transparent corners.

## Size Results

- `App/Resources/AppIcon-master-1024.png`: reduced from about `776 KB` to about `4 KB`
- `App/Resources/Assets.xcassets/AppIcon.appiconset`: reduced from about `1.3 MB` to about `44 KB`
- Both size targets were met: master `<= 100 KB`, iconset `<= 250 KB`

## Files Touched

- `App/Resources/AppIcon-master-1024.png`
- `App/Resources/Assets.xcassets/AppIcon.appiconset/*.png`
- `.planning/quick/260326-8jz-redraw-the-app-icon-in-a-minimal-style-a/260326-8jz-PLAN.md`
- `.planning/quick/260326-8jz-redraw-the-app-icon-in-a-minimal-style-a/260326-8jz-SUMMARY.md`
- `.planning/STATE.md`

## Verification

- Confirmed the regenerated master is `1024x1024` and the exported iconset still contains every required macOS app icon slot.
- Confirmed the source PNGs retain transparency (`alpha_extrema = (0, 255)`) rather than flattening to a solid square.
- `actool` successfully compiled the new `AppIcon` asset and emitted both `Assets.car` and `AppIcon.icns` before the app build stopped on unrelated Swift compile errors.
- Extracted the built `AppIcon.icns` back to an `.iconset` and visually confirmed the packaged icon matches the new minimal design.

## Blockers

- A full `xcodebuild` completion is currently blocked by existing Swift errors in [SettingsCopyFormatter.swift](/Users/congbo/workspace/default-editor-switcher/App/Features/Settings/SettingsCopyFormatter.swift#L55) and [SettingsCopyFormatter.swift](/Users/congbo/workspace/default-editor-switcher/App/Features/Settings/SettingsCopyFormatter.swift#L68), unrelated to the icon resource changes.

## Notes

- No atomic git commit was created for this quick task because the repository already had unrelated in-progress changes in the working tree.
