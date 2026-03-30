<div align="center">

# Default Editor Switcher

[English](README.md) · [简体中文](README.zh-CN.md) · **日本語**

**Vibe Coding の時代に、複数の AI エディタを手元に置いて使い分ける開発者のための、軽快な macOS メニューバーアプリです。**

**`.py`、`.tsx`、`.html`、`.css`、`.java`、`.md` のようなファイル群の既定アプリをワンクリックでまとめて切り替えられます。Finder で種類ごとに一つずつ変更する手間や設定漏れを減らすためのツールです。**

</div>

## このプロジェクトについて

Vibe Coding では、一つのエディタだけで一日を終えるほうが珍しくなりました。Cursor で一つの流れを回し、Windsurf で別の作業を並行し、Zed で軽いループを回し、VS Code や JetBrains が特定の言語や作業モードを受け持つ。異なる種類のタスクが同時に走るほど、複数のエディタを開いておくのが自然になります。

切り替えの理由もかなり現実的です。作業ごとに向いているエディタが違う、別のタスクがすでに走っている、あるいは token quota や予算上限に達したので別の道具へ移りたい。`Default Editor Switcher` は、そんな高頻度の切り替えのためのツールです。複数のファイル種別をまとめてネイティブに切り替えられるので、Finder や Git ツールから開いたファイルも今ほしいエディタへ自然に流れ、すでに別のエディタで開いている作業をむやみに乱しません。別のプロジェクトに移って使いたいエディタが変わるときも、`Open With` を種類ごとに後始末し続ける必要がなくなります。

発想は [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher) のミニマルな切り替え体験に近いですが、対象はブラウザではなくエディタです。

## できること

- メニューバーから現在のグローバルなテキスト既定エディタをすぐ確認できます。
- refresh で利用可能なエディタ一覧を更新し、内蔵の推奨エディタと macOS が対応を宣言しているアプリを再検出できます。
- ワンクリックで内蔵のグローバルテキスト対象を別のエディタへ切り替えられます。
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

## License

[MIT](LICENSE)
