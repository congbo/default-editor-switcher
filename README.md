<div align="center">

# Default Editor Switcher

**English** · [简体中文](README.zh-CN.md) · [日本語](README.ja-JP.md)

**A lightweight macOS menu bar app for developers living in the Vibe Coding era, with a handful of AI editors always within reach.**

**One click switches all kinds of text-type files to a different default editor, without the tedious Finder ritual of changing them one file type at a time. Built-in text types are ready out of the box, and `Global Text Types` in Settings can add custom extensions to the same global switch.**

</div>

<p align="center">
  <img src="docs/images/menu-bar-runtime.png" alt="Runtime menu bar screenshot" width="360" />
</p>

## Why This Exists

Vibe Coding changed what a developer desktop looks like. Cursor for one stream of work, Windsurf for another, Zed for a lighter loop, VS Code for the familiar setup, JetBrains for a language-specific pass. Once different kinds of tasks are running in parallel, keeping several editors open stops feeling excessive and starts feeling normal.

And the reason to switch keeps changing too. One task fits a different editor better, another is already running somewhere else, or a token budget simply ran dry and forces you to move. `Default Editor Switcher` is built for that rhythm: a native, one-click way to move multiple file types together, so files opened from Finder or a Git client land in the editor you actually want, without hijacking the workspace already open for something else. When you shift from one project to another and your editor preference changes with it, you can switch the file-opening defaults once instead of cleaning up `Open With` choices type by type.

It is loosely inspired by [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher), but aimed at editors instead of browsers.

## What You Can Do

- Shows your current global text default editor directly from the menu bar.
- Lets you refresh the available editor list by rediscovering both the built-in recommended editors and the apps macOS says can handle those file types.
- One click switches the built-in global text scope to another editor.
- Lets `Global Text Types` in Settings add, enable, disable, and remove custom extensions. If macOS cannot resolve one yet, the app keeps it in the list and skips it during the global switch.
- Gives you a dedicated settings window for launch-at-login, recommended app ordering, app language, and global text type inclusion, including custom extensions.

## Troubleshooting

### macOS says the app is damaged and can't be opened

Because macOS applies quarantine checks to apps downloaded outside the App Store, you may see this warning the first time you launch the app.

1. Command-line fix (recommended):

   ```bash
   sudo xattr -rd com.apple.quarantine "/Applications/DefaultEditorSwitcher.app"
   ```

   If you moved or renamed the app, adjust the path accordingly.

2. Or open it from `System Settings` -> `Privacy & Security` and click `Open Anyway`.

## Development

Build:

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

Test:

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

### Development Notes

- We model system-wide default editor changes through Launch Services because Finder's `Open With` and `Change All` flow ultimately lands in the same handler system. For a tool that changes the Mac's real default open behavior instead of doing one-off opens, `LSSetDefaultRoleHandlerForContentType` and `LSCopyDefaultRoleHandlerForContentType` are the right public APIs to reason about first.
- On macOS, a file type's default app can be split across different Launch Services roles. Finder double-click behavior may follow a different role than the one you first inspect.
- When validating a default-editor change for document-like types such as Markdown, verify both the displayed default app and the real open behavior from Finder. Treat mismatched `all`, `viewer`, and `editor` role state as a real inconsistency, not a Finder-only display issue; `UTType` plus role-aware readback is what makes the result explainable.
- Treat `~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist` as a diagnostic and low-level mutation layer, not as the public source of truth. Editing that plist can help with silent writes, recovery, and debugging, but it is still an implementation detail beneath the documented Launch Services model.
- Latest research as of April 1, 2026: a Scripting OS X article published on March 24, 2026 and updated on March 27, 2026 reports that macOS 26.4 now shows user confirmation prompts for API or script driven file-type default-app changes. One bulk switch can therefore trigger many dialogs, and choosing `Keep` can leave some types unchanged. Apple has not clearly documented this as an official policy change yet; Finder's `Get Info` -> `Open with` -> `Change All` path is still the user-facing baseline and is currently reported to avoid the extra prompt.
- Common Launch Services inspection and refresh commands:

  ```bash
  plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # Quick top-level dump of the user Launch Services plist.

  defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # Read the plist through defaults for another plain-text view.

  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc -R -all user,system,local,network
  # Rebuild and garbage-collect Launch Services registrations.

  killall lsd
  # Restart the Launch Services daemon so the system reloads handler state.
  ```

- These commands are for development diagnostics and recovery. They do not guarantee a way around the macOS 26.4 confirmation prompts.

## License

[MIT](LICENSE)
