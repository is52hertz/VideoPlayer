<!--
README.md — written to be both human-friendly on GitHub and learning-friendly
for AI assistants opening the repo. The HTML below renders on github.com.
-->

<p align="right">
  <a href="README.md">English</a> ·
  <a href="README-zh_cn.md">简体中文</a> ·
  <b>繁體中文</b> ·
  <a href="README-ja.md">日本語</a> ·
  <a href="README-ko.md">한국어</a> ·
  <a href="README-ru.md">Русский</a>
</p>

> **由 AI 打造,由人類執導。**
> 本專案從頭到尾皆以 **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI** 開發。
> AI 負責實作,開發者則擔任 **創意總監與 QA**。
> `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 以及 `.claude/` `.gemini/` `.kiro/` 等技能資料夾都是 **刻意提交** 的 — 這是一個學習導向的專案。歡迎閱讀、Fork、送 PR。這裡的所有東西都值得被研究。

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player icon" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  一款原生、本地優先的影片播放器,支援 <b>macOS · iOS · iPadOS</b>,<br/>
  以 SwiftUI &amp; AVFoundation 打造,搭配 Liquid&nbsp;Glass 美學。
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 專案理念

| | |
|---|---|
| **純原生** | 不使用 Electron、React Native、Flutter 或 WebView。僅以 SwiftUI + AVFoundation 實作。 |
| **本地優先** | 沒有帳號、沒有雲端同步、不抓取線上資料。你的檔案永遠屬於你。 |
| **Liquid Glass** | iOS 26 / iPadOS 26 / macOS 26 的材質 — 流動的透明感、有機的模糊,完全遵循 HIG。 |
| **AI 驅動工作流程** | 由 AI 負責實作,由人類進行程式碼審查。詳見 `AGENTS.md`。 |

---

## ✨ 特色功能

- 🎬 **原生播放引擎** — 在乾淨的 `PlayerEngine` 協定背後封裝 `AVPlayer`。
- 🪟 **Liquid Glass 介面** — 在 iOS 26+ 上採用 `.glassEffect` / `.glassEffectTransition(.materialize)`。
- 👆 **觸控優先的 iOS 控制項** — 自動隱藏面板、拖曳手勢、玻璃藥丸元件。
- 🔊 **系統音量橋接** — KVO + `MPVolumeView` 同步,並重新打造客製化的觸覺回饋。
- 🖥️ **原生 macOS 外殼** — 視窗選單與生命週期(在 iPad 上提供等效的 iPadOS 體驗)。
- 🔒 **零遙測** — 任何資料都不會離開裝置。永遠不會。

### 🚧 開發藍圖

完整計畫請見 [`TODO.md`](TODO.md)。重點項目:

- 🐛 在前景使用實體按鍵調整音量時,音量藥丸未能同步。
- 📱 直向模式下,頂端藥丸需避開動態島(Dynamic Island)。
- 🎛️ 手勢系統:半螢幕長按倍速、雙擊跳轉、垂直滑動調整亮度 / 音量。
- ⚡ 倍速藥丸(0.5× / 1× / 2× / 3×),搭配 Liquid Glass 選取狀態。
- 🎞️ 資訊面板 — 仿 Apple TV 風格的底部疊層,含縮圖與中繼資料。
- 📺 PIP 與 AirPlay 支援。
- 🌀 進度條物理效果與橡皮筋回饋。

---

## 🏗 架構

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

嚴格遵守 MVVM。View 絕不直接觸碰 `AVPlayer`、持久化或服務層。唯一被允許的例外是對效能敏感的手勢狀態(參見 `AGENTS.md` § Architecture)。

---

## 🤖 與 AI 助理協作

本 Repo 是一個 **AI 原生開發** 的實戰範例。讓 AI 助理在第一天就能順利上手所需的一切都已納入版控:

| 檔案 / 資料夾 | 用途 |
|---|---|
| `AGENTS.md` | **單一事實來源** — 規則、原則、範圍紀律、工作流程。 |
| `CLAUDE.md` / `GEMINI.md` | 各工具的入口檔(內容大多鏡像自 `AGENTS.md`)。 |
| `.claude/skills/`  | Claude Code 專案專屬技能(`glass-know`、`hig-doctor`)。 |
| `.gemini/skills/`  | Gemini CLI 的對應版本。 |
| `.kiro/skills/` `.kiro/agents/` | Kiro CLI 的工作流程。 |
| `TODO.md` | 下一次迭代的詳細任務清單,範圍皆已驗證。 |
| `issues-*.md` `Refer/` | AI 助理會參考的長篇情境筆記。 |

**個人化設定不會被提交。** `*.local.json`、憑證、對話紀錄與暫時狀態皆已加入 gitignore。當你 Fork 之後,你本地的開關仍會留在本地。

> 💡 第一次接觸 AI 輔助的 iOS 開發?請先閱讀 `AGENTS.md`,然後用上述 **任何一款** CLI 開啟此 Repo。各種技能會根據情境自動啟用。

---

## 🛠 建置與執行

**需求**

- Xcode 26(iOS 26 / macOS 26 SDK)
- Swift 6
- macOS 26 主機(用於 macOS target)

**開始使用**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**從命令列建置與測試**

```bash
# Build
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# Test
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**透過 Claude Code + XcodeBuildMCP 執行**(建議用於 AI 工作流程)

```text
> /run         # launches the app on the configured simulator
> /verify      # runs the change end-to-end and reports
```

---

## 🤝 參與貢獻

歡迎送 PR — 本專案積極鼓勵 **Fork、實驗,以及以學習為目的的 PR**。

- 請先閱讀 `AGENTS.md`;其中的範圍紀律規則同時適用於人類與 AI。
- 變更請保持小而專注。一個 commit = 一個邏輯單位。
- 建置必須維持綠燈:推送前請執行 `xcodebuild … build`。
- Commit 格式:`^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

Issues、Discussions 以及「我從這個 Repo 學到了 X」之類的筆記同樣歡迎。

---

## 📜 授權

採用 **GNU General Public License v3.0**(GPL-3.0)授權釋出。

> 為什麼選 GPL?本專案存在的目的是為了教學。GPL 確保所有衍生作品 — 包含由 AI 生成的 Fork — 都會保持開源,讓下一位學習者也能研究它們。如果你以此為基礎打造了什麼,請也分享回來。

完整授權內容請見 [`LICENSE`](LICENSE)。

---

<p align="center">
  <sub>以 <code>SwiftUI</code> 與大量的 <code>/clear</code> 打造而成。</sub>
</p>
