<div align="center">

# Default Editor Switcher

[English](README.md) · **简体中文** · [日本語](README.ja-JP.md)

**一个轻巧顺手的 macOS 菜单栏工具，给那些已经进入 Vibe Coding 时代、电脑里常备好几个 AI 编辑器的开发者。**

**一键把 `.py`、`.tsx`、`.html`、`.css`、`.java`、`.md` 这类文件的默认打开方式一起切到另一款编辑器，不用再去 Finder 里按类型逐个修改，既繁琐，也很容易漏掉。**

</div>

## 项目缘起

到了 Vibe Coding 这一步，很少有人只靠一个编辑器干完一天的活。Cursor 跑一个任务，Windsurf 跑另一个，Zed 负责更轻的回路，VS Code 或 JetBrains 接住特定语言和工作模式。并发处理不同类型的任务时，Mac 上常驻好几个编辑器，早就成了常态。

真正麻烦的不是装了多少编辑器，而是默认打开方式总得跟着切。这个任务更适合另一个编辑器，另一个任务已经在别处跑着，或者 token 配额刚好见底，只能临时换工具。`Default Editor Switcher` 就是为这种高频切换准备的：把一组常见代码和文本文件的默认打开方式一次切过去。这样你从 Finder 或 Git 工具里点开文件时，它会更自然地落到当前想用的编辑器，而不是打断另一个已经打开的工作区；等你切到另一个项目、想换一套编辑器习惯时，也不用再回头把 `Open With` 一项项收尾。

它借鉴了 [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher) 那种干脆的切换体验，只是这次目标从浏览器变成了编辑器。

## 你可以做什么

- 直接在菜单栏展示当前全局文本默认编辑器。
- 从内置推荐编辑器名单和 macOS 已声明的可处理应用中发现可用编辑器。
- 通过简短菜单交互，把内置的全局文本范围切换到另一个编辑器。
- 提供原生设置窗口，用于配置开机启动、菜单栏推荐应用顺序，以及应用语言。

## 本地开发

构建：

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

测试：

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

## 使用 GSD 开发

这个项目使用 [gsd-build/get-shit-done: A light-weight and powerful meta-prompting, context engineering and spec-driven development system for Claude Code by TACHES.](https://github.com/gsd-build/get-shit-done) 进行开发。

感谢 GSD 项目为这个仓库提供工作流和结构化开发方式。

## License

[MIT](LICENSE)
