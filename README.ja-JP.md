<div align="center">

# Default Editor Switcher

[English](README.md) · [简体中文](README.zh-CN.md) · **日本語**

**Vibe Coding の時代に、複数の AI エディタを手元に置いて使い分ける開発者のための、軽快な macOS メニューバーアプリです。**

**`.py`、`.tsx`、`.html`、`.css`、`.java`、`.md` のようなファイル群の既定アプリをワンクリックでまとめて切り替えられます。Finder で種類ごとに一つずつ変更する手間や設定漏れを減らすためのツールです。**

</div>

## このプロジェクトについて

Vibe Coding では、一つのエディタだけで一日を終えるほうが珍しくなりました。Cursor で一つの流れを回し、Windsurf で別の作業を並行し、Zed で軽いループを回し、VS Code や JetBrains が特定の言語や作業モードを受け持つ。異なる種類のタスクが同時に走るほど、複数のエディタを開いておくのが自然になります。

切り替えの理由もかなり現実的です。作業ごとに向いているエディタが違う、別のタスクがすでに走っている、あるいは token quota や予算上限に達したので別の道具へ移りたい。`Default Editor Switcher` は、そんな高頻度の切り替えのためのツールです。複数のファイル種別をまとめてネイティブに切り替えられるので、Finder や Git ツールから開いたファイルも今ほしいエディタへ自然に流れ、すでに別のエディタで開いている作業をむやみに乱しません。別のプロジェクトに移って使いたいエディタが変わるときも、`Open With` を種類ごとに後始末し続ける必要がなくなります。

発想は [`default-browser`](https://sindresorhus.com/default-browser) のミニマルな切り替え体験に近いですが、対象はブラウザではなくエディタです。

## できること

- メニューバーから現在のグローバルなテキスト既定エディタをすぐ確認できます。
- 内蔵の推奨エディタ一覧と、macOS がそのファイル種別を開けると宣言しているアプリの両方から候補を見つけられます。
- 短いメニュー操作で、内蔵のグローバルテキスト対象を別のエディタへ切り替えられます。
- 起動時実行、メニューの推奨アプリ順、アプリ言語を設定できる専用の設定ウィンドウを備えています。

## 開発

ビルド:

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

テスト:

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

## GSD で開発

このプロジェクトは [gsd-build/get-shit-done: A light-weight and powerful meta-prompting, context engineering and spec-driven development system for Claude Code by TACHES.](https://github.com/gsd-build/get-shit-done) を使って開発しています。

このリポジトリのワークフローと構造を支えている GSD プロジェクトに感謝します。

## License

[MIT](LICENSE)
