<div align="center">

# Default Editor Switcher

[English](README.md) · [简体中文](README.zh-CN.md) · **日本語**

**Vibe Coding の時代に、複数の AI エディタを手元に置いて使い分ける開発者のための、軽快な macOS メニューバーアプリです。**

**さまざまなテキスト系ファイルの既定アプリをワンクリックでまとめて切り替えられます。Finder で種類ごとに一つずつ変更する手間や設定漏れを減らすためのツールです。よく使うテキスト系タイプは最初から含まれており、Settings の `Global Text Types` からカスタム拡張子を追加して同じグローバル切り替えに含めることもできます。**

</div>

<p align="center">
  <img src="docs/images/menu-bar-runtime.png" alt="実行時のメニューバー画面" width="360" />
</p>

## このプロジェクトについて

Vibe Coding では、一つのエディタだけで一日を終えるほうが珍しくなりました。Cursor で一つの流れを回し、Windsurf で別の作業を並行し、Zed で軽いループを回し、VS Code や JetBrains が特定の言語や作業モードを受け持つ。異なる種類のタスクが同時に走るほど、複数のエディタを開いておくのが自然になります。

切り替えの理由もかなり現実的です。作業ごとに向いているエディタが違う、別のタスクがすでに走っている、あるいは token quota や予算上限に達したので別の道具へ移りたい。`Default Editor Switcher` は、そんな高頻度の切り替えのためのツールです。複数のファイル種別をまとめてネイティブに切り替えられるので、Finder や Git ツールから開いたファイルも今ほしいエディタへ自然に流れ、すでに別のエディタで開いている作業をむやみに乱しません。別のプロジェクトに移って使いたいエディタが変わるときも、`Open With` を種類ごとに後始末し続ける必要がなくなります。

発想は [`default-browser-switcher`](https://github.com/congbo/default-browser-switcher) のミニマルな切り替え体験に近いですが、対象はブラウザではなくエディタです。

## できること

- メニューバーから現在のグローバルなテキスト既定エディタをすぐ確認できます。
- refresh で利用可能なエディタ一覧を更新し、内蔵の推奨エディタと macOS が対応を宣言しているアプリを再検出できます。
- ワンクリックで内蔵のグローバルテキスト対象を別のエディタへ切り替えられます。
- Settings の `Global Text Types` でカスタム拡張子の追加・有効化・無効化・削除ができます。macOS がまだ解決できない拡張子は一覧に保持したまま、グローバル切り替え時にはスキップされます。
- 起動時実行、メニューの推奨アプリ順、アプリ言語、そしてカスタム拡張子を含むグローバルテキスト対象の管理ができる専用の設定ウィンドウを備えています。

## トラブルシューティング

### macOS で「アプリが壊れているため開けません」と表示される場合

macOS では App Store 外から入手したアプリに quarantine の安全確認が入るため、初回起動時にこの警告が出ることがあります。

1. ターミナルで修復する方法（推奨）:

   ```bash
   sudo xattr -rd com.apple.quarantine "/Applications/DefaultEditorSwitcher.app"
   ```

   アプリ名や配置場所を変更している場合は、実際のパスに合わせてください。

2. または `システム設定` -> `プライバシーとセキュリティ` から `このまま開く` を選んでください。

## 開発

ビルド:

```bash
xcodebuild -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS' build
```

テスト:

```bash
xcodebuild test -scheme DefaultEditorSwitcher -project DefaultEditorSwitcher.xcodeproj -destination 'platform=macOS'
```

### 開発時の注意

- このプロダクトが Launch Services を既定エディタ切り替えの主モデルとして扱うのは、Finder の `Open With` / `Change All` も最終的には同じ handler の仕組みに乗っているからです。変更したいのはアプリ内の一時的な開き方ではなく macOS の実際の既定動作なので、まず `LSSetDefaultRoleHandlerForContentType` と `LSCopyDefaultRoleHandlerForContentType` という公開 API を軸に考える必要があります。
- macOS では、同じファイルタイプの既定アプリ状態が Launch Services の複数ロールに分かれていることがあります。Finder のダブルクリックが参照するロールは、最初に確認した既定項目と一致しない場合があります。
- Markdown のようなドキュメント系タイプで既定エディタ切り替えを検証するときは、表示上の既定アプリだけでなく、Finder から実際にどう開くかも確認してください。`all`、`viewer`、`editor` の状態が揃っていないなら、Finder の見かけだけの問題ではなく実際の不整合として扱うべきです。結果を説明可能にするには、`UTType` とロールをセットで読み返す必要があります。
- `~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist` は、診断やサイレント書き込み、復旧時に確認する低レベルの層として扱うのが適切です。Launch Services API よりも権威のある唯一の真実として README に書くべきではなく、あくまで実装詳細です。
- `2026-04-01` 時点の最新調査では、Scripting OS X の記事（`2026-03-24` 公開、`2026-03-27` 更新）により、`macOS 26.4` では API やスクリプト経由でファイルタイプの既定アプリを変更するとユーザー確認ダイアログが出ることが報告されています。つまり、一括切り替え 1 回で確認ダイアログが何度も続けて出る可能性があり、実態としては「タイプごとに 1 回確認」です。ユーザーが `Keep` を押すと、そのタイプは元の既定アプリのまま残ります。Apple の公式ドキュメントはまだこれを明確な正式仕様変更として説明しておらず、Finder の `Get Info` -> `Open with` -> `Change All` は依然としてユーザー向けの基準手順で、現時点では追加ダイアログを避けられる経路として報告されています。
- よく使う Launch Services plist / 更新コマンド:

  ```bash
  plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # ユーザーの Launch Services plist 全体をざっと確認します。

  defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
  # defaults 経由で plist を読み、別のテキスト表示で確認します。

  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -gc -R -all user,system,local,network
  # Launch Services の登録データベースを再構築し、不要項目を掃除します。

  killall lsd
  # Launch Services デーモンを再起動して handler 状態を再読込させます。
  ```

- これらのコマンドは主に開発時の調査と復旧のためのもので、`macOS 26.4` の確認ダイアログを回避する保証はありません。

## License

[MIT](LICENSE)
