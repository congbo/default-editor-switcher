<div align="center">

# Default Editor Switcher

[English](README.md) · **简体中文** · [日本語](README.ja-JP.md)

**一个轻巧顺手的 macOS 菜单栏工具，给那些已经进入 Vibe Coding 时代、电脑里常备好几个 AI 编辑器的开发者。**

**一键把各类文本类型文件的默认打开方式一起切到另一款编辑器，不用再去 Finder 里按类型逐个修改，既繁琐，也很容易漏掉。常见文本类型开箱即用，同时也可以在 Settings 的 `Global Text Types` 里添加自定义扩展名，把它们纳入同一套全局切换。**

</div>

<p align="center">
  <img src="docs/images/menu-bar-runtime.png" alt="运行时菜单栏截图" width="360" />
</p>

## 项目缘起

到了 Vibe Coding 这一步，很少有人只靠一个编辑器干完一天的活。Cursor 跑一个任务，Windsurf 跑另一个，Zed 负责更轻的回路，VS Code 或 JetBrains 接住特定语言和工作模式。并发处理不同类型的任务时，Mac 上常驻好几个编辑器，早就成了常态。

真正麻烦的不是装了多少编辑器，而是默认打开方式总得跟着切。这个任务更适合另一个编辑器，另一个任务已经在别处跑着，或者 token 配额刚好见底，只能临时换工具。`Default Editor Switcher` 就是为这种高频切换准备的：把一组常见代码和文本文件的默认打开方式一次切过去。这样你从 Finder 或 Git 工具里点开文件时，它会更自然地落到当前想用的编辑器，而不是打断另一个已经打开的工作区；等你切到另一个项目、想换一套编辑器习惯时，也不用再回头把 `Open With` 一项项收尾。

它借鉴了 [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher) 那种干脆的切换体验，只是这次目标从浏览器变成了编辑器。

## 你可以做什么

- 直接在菜单栏展示当前全局文本默认编辑器。
- 支持 refresh 可用编辑器列表，重新发现内置推荐编辑器和 macOS 已声明可处理目标类型的应用。
- 一键切换内置的全局文本默认编辑器。
- `Global Text Types` 支持添加、启用、禁用和删除自定义扩展名；如果某个扩展名暂时无法被 macOS 解析，应用会保留它，但在全局切换时跳过。
- 提供原生设置窗口，用于配置开机启动、菜单栏推荐应用顺序、应用语言，以及全局文本类型范围（包括自定义扩展名）。

## 常见问题排查

### macOS 提示“应用已损坏，无法打开”？

由于 macOS 会对非 App Store 下载的应用执行 quarantine 安全检查，你第一次打开应用时可能会看到这条提示。

1. 命令行修复（推荐）：

   ```bash
   sudo xattr -rd com.apple.quarantine "/Applications/DefaultEditorSwitcher.app"
   ```

   如果你移动过应用位置，或者改过应用名称，请按实际路径调整这条命令。

2. 或者：打开“系统设置” -> “隐私与安全性”，点击“仍要打开”。

## 本地开发

构建：

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

测试：

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

### 开发注意事项

- 这个产品把 Launch Services 作为系统默认编辑器切换的主模型，是因为 Finder 里的 `Open With` / `Change All` 最终也是落到同一套 handler 机制上。我们要改的是 macOS 真实的默认打开行为，而不是应用内的一次性打开，所以首先应围绕 `LSSetDefaultRoleHandlerForContentType` 和 `LSCopyDefaultRoleHandlerForContentType` 这类公开 API 来建模。
- 在 macOS 上，同一种文件类型的默认应用可能会被 Launch Services 拆分到不同角色里；Finder 双击实际走的角色，不一定和你最先看到的那个默认项一致。
- 验证 Markdown 这类文档型文件的默认编辑器切换时，不要只看显示出的默认应用，还要确认 Finder 的实际打开行为。只要 `all`、`viewer`、`editor` 三类角色没有收敛一致，就应视为真实不一致，而不是 Finder 单纯“显示错了”；也只有把 `UTType` 和 role 一起读回来看，结果才是可解释的。
- `~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist` 更适合作为诊断、静默写入和修复时要看的低层文件，而不应被描述成比 Launch Services API 更权威的“唯一真相源”。直接改 plist 仍然属于实现细节，不是 Apple 对外推荐的主接口。
- 截至 `2026-04-01` 的最新 research：Scripting OS X 在 `2026-03-24` 发布、`2026-03-27` 更新的文章指出，`macOS 26.4` 会对“通过 API 或脚本修改文件类型默认打开方式”弹出用户确认框。因此，一次批量切换可能连续弹很多次，本质上是“每个类型一次确认”；如果用户点了 `Keep`，部分类型就会保留原来的默认应用。Apple 官方文档目前还没有把这件事清晰写成正式策略变更；Finder 的 `Get Info` -> `Open with` -> `Change All` 仍然是面向用户的基线路径，而且当前社区观察认为它暂时不会触发这类额外弹窗。
- 常用的 Launch Services plist/刷新命令：

  ```bash
  plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # 快速查看当前用户 Launch Services plist 的顶层内容。

  defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # 用 defaults 再读一遍 plist，获得另一种纯文本视图。

  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc -R -all user,system,local,network
  # 重建并清理 Launch Services 注册数据库。

  killall lsd
  # 重启 Launch Services 守护进程，让系统重新加载 handler 状态。
  ```

- 这些命令主要用于开发排查和恢复，不保证能绕过 `macOS 26.4` 的确认弹窗。

## License

[MIT](LICENSE)
