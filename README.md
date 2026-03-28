<div align="center">

# Default Editor Switcher

**English** · [简体中文](README.zh-CN.md) · [日本語](README.ja-JP.md)

**A lightweight macOS menu bar app for developers living in the Vibe Coding era, with a handful of AI editors always within reach.**

**One click switches groups of files like `.py`, `.tsx`, `.html`, `.css`, `.java`, and `.md` to a different default editor, without the tedious Finder ritual of changing them one file type at a time.**

</div>

## Why This Exists

Vibe Coding changed what a developer desktop looks like. Cursor for one stream of work, Windsurf for another, Zed for a lighter loop, VS Code for the familiar setup, JetBrains for a language-specific pass. Once different kinds of tasks are running in parallel, keeping several editors open stops feeling excessive and starts feeling normal.

And the reason to switch keeps changing too. One task fits a different editor better, another is already running somewhere else, or a token budget simply ran dry and forces you to move. `Default Editor Switcher` is built for that rhythm: a native, one-click way to move multiple file types together, so files opened from Finder or a Git client land in the editor you actually want, without hijacking the workspace already open for something else. When you shift from one project to another and your editor preference changes with it, you can switch the file-opening defaults once instead of cleaning up `Open With` choices type by type.

It is loosely inspired by [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher), but aimed at editors instead of browsers.

## What You Can Do

- Shows your current global text default editor directly from the menu bar.
- Discovers available editors from both a curated recommendation list and the apps macOS says can handle those file types.
- Switches the built-in global text scope to another editor through a short menu interaction.
- Gives you a dedicated settings window for launch-at-login, recommended app ordering, and app language.

## Development

Build:

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

Test:

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

## Built with GSD

This project is being developed with [gsd-build/get-shit-done: A light-weight and powerful meta-prompting, context engineering and spec-driven development system for Claude Code by TACHES.](https://github.com/gsd-build/get-shit-done)

Thanks to the GSD project for the workflow and structure behind this repo.

## License

[MIT](LICENSE)
