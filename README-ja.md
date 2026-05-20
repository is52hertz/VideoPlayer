<!--
README.md — written to be both human-friendly on GitHub and learning-friendly
for AI assistants opening the repo. The HTML below renders on github.com.
-->

<p align="right">
  <a href="README.md">English</a> ·
  <a href="README-zh_cn.md">简体中文</a> ·
  <a href="README-zh_tw.md">繁體中文</a> ·
  <b>日本語</b> ·
  <a href="README-ko.md">한국어</a> ·
  <a href="README-ru.md">Русский</a>
</p>

> **AIで構築し、人間がディレクションする。**
> このプロジェクトは **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI** によってエンドツーエンドで開発されています。
> 実装はAIが担当し、開発者は **クリエイティブディレクター兼QA** として機能します。
> `AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、そして `.claude/` `.gemini/` `.kiro/` のスキルフォルダーは **意図的に** コミットされています — これは学習用プロジェクトです。読んで、フォークして、PRを送ってください。すべてが学習対象として用意されています。

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player icon" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  <b>macOS · iOS · iPadOS</b> 向けのネイティブかつローカルファーストな動画プレーヤー、<br/>
  SwiftUI &amp; AVFoundation と Liquid&nbsp;Glass デザインで構築。
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 プロジェクトの理念

| | |
|---|---|
| **ネイティブのみ** | Electron、React Native、Flutter、WebViewは使いません。SwiftUI + AVFoundation のみ。 |
| **ローカルファースト** | アカウント不要、クラウド同期なし、オンラインスクレイピングなし。あなたのファイルはあなたのもの。 |
| **Liquid Glass** | iOS 26 / iPadOS 26 / macOS 26 のマテリアル — 流体的な透明感、有機的なブラー、HIG準拠。 |
| **AI駆動のワークフロー** | 実装はAI、コードレビューは人間。詳しくは `AGENTS.md` を参照。 |

---

## ✨ 機能

- 🎬 **ネイティブな再生エンジン** — クリーンな `PlayerEngine` プロトコルの背後にある `AVPlayer`。
- 🪟 **Liquid Glass UI** — iOS 26+ での `.glassEffect` / `.glassEffectTransition(.materialize)`。
- 👆 **タッチファーストの iOS コントロール** — 自動非表示パネル、スクラブジェスチャー、ガラス調のピル。
- 🔊 **システム音量ブリッジ** — KVO + `MPVolumeView` 同期、カスタムハプティクスの再現。
- 🖥️ **ネイティブな macOS シェル** — ウィンドウメニューとライフサイクル(iPadではiPadOS相当)。
- 🔒 **テレメトリゼロ** — デバイスから何も送信されません。決して。

### 🚧 ロードマップ

完全なプランは [`TODO.md`](TODO.md) を参照してください。ハイライト:

- 🐛 フォアグラウンドでハードウェアキーで音量変更した際に音量ピルが同期しない問題。
- 📱 縦向きモードのトップピルにおける Dynamic Island の回避。
- 🎛️ ジェスチャーシステム: 半画面長押しで速度変更、ダブルタップでスキップ、垂直方向で明るさ/音量。
- ⚡ Liquid-Glass の選択状態を持つ速度ピル (0.5× / 1× / 2× / 3×)。
- 🎞️ 情報パネル — サムネイル+メタデータ付きの Apple-TV スタイルのボトムオーバーレイ。
- 📺 PIP と AirPlay のサポート。
- 🌀 プログレスバーの物理挙動とラバーバンドフィードバック。

---

## 🏗 アーキテクチャ

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

厳格な MVVM。View は `AVPlayer`、永続化、サービスに直接触れません。唯一認められた例外は、パフォーマンスに敏感なジェスチャー状態です(`AGENTS.md` § Architecture を参照)。

---

## 🤖 AI アシスタントとの連携

このリポジトリは **AIネイティブ開発** の実践例です。アシスタントが初日から生産的に動くために必要なものはすべてコミット済みです:

| ファイル / フォルダー | 目的 |
|---|---|
| `AGENTS.md` | **信頼できる唯一の情報源(SSOT)** — ルール、信条、スコープ規律、ワークフロー。 |
| `CLAUDE.md` / `GEMINI.md` | ツールごとのエントリーポイント(ほぼ `AGENTS.md` のミラー)。 |
| `.claude/skills/`  | プロジェクト固有の Claude Code スキル(`glass-know`、`hig-doctor`)。 |
| `.gemini/skills/`  | Gemini CLI の対応版。 |
| `.kiro/skills/` `.kiro/agents/` | Kiro CLI のワークフロー。 |
| `TODO.md` | スコープが検証済みの、詳細な次回イテレーションタスクリスト。 |
| `issues-*.md` `Refer/` | アシスタントが参照する長文のコンテキストノート。 |

**ユーザー個別の設定はコミットされません。** `*.local.json`、認証情報、トランスクリプト、一時的な状態はすべて gitignore されています。フォークすればローカルのトグルはローカルのまま残ります。

> 💡 AI支援による iOS 開発が初めてですか? まず `AGENTS.md` を読んでから、リスト内の **任意の** CLI でリポジトリを開いてください。スキルはコンテキストに応じて自動的にアクティブになります。

---

## 🛠 ビルドと実行

**必要要件**

- Xcode 26 (iOS 26 / macOS 26 SDK)
- Swift 6
- macOS 26 ホスト(macOS ターゲット向け)

**始めかた**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**コマンドラインでのビルドとテスト**

```bash
# Build
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# Test
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**Claude Code + XcodeBuildMCP 経由で実行**(AIワークフロー推奨)

```text
> /run         # launches the app on the configured simulator
> /verify      # runs the change end-to-end and reports
```

---

## 🤝 コントリビュート

PRは歓迎します — このプロジェクトは **フォーク、実験、学習目的のPR** を積極的に推奨します。

- まず `AGENTS.md` を読んでください。スコープ規律のルールは人間にもAIにも等しく適用されます。
- 変更は小さく焦点を絞って。1コミット = 1つの論理単位。
- ビルドは常にグリーンに保つこと: プッシュ前に `xcodebuild … build` を実行してください。
- コミット形式: `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

イシュー、ディスカッション、そして「このリポジトリから X を学びました」というノートも同様に歓迎します。

---

## 📜 ライセンス

**GNU General Public License v3.0** (GPL-3.0) の下でリリースされています。

> なぜ GPL なのか? このプロジェクトは教えることを目的に存在します。GPL は派生物 — AI生成のフォークも含めて — がオープンであり続けることを保証し、次の学習者もそれを学べるようにします。これを土台に何かを作ったら、それをコミュニティに還元してください。

全文は [`LICENSE`](LICENSE) を参照してください。

---

<p align="center">
  <sub>Made with <code>SwiftUI</code> + a lot of <code>/clear</code>.</sub>
</p>
