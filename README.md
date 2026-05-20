<!--
README.md — written to be both human-friendly on GitHub and learning-friendly
for AI assistants opening the repo. The HTML below renders on github.com.
-->

<p align="right">
  <b>English</b> ·
  <a href="README-zh_cn.md">简体中文</a> ·
  <a href="README-zh_tw.md">繁體中文</a> ·
  <a href="README-ja.md">日本語</a> ·
  <a href="README-ko.md">한국어</a> ·
  <a href="README-ru.md">Русский</a>
</p>

> **Built with AI, directed by a human.**
> This project is developed end-to-end with **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI**.
> AI handles the implementation; the developer acts as **creative director and QA**.
> `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and the `.claude/` `.gemini/` `.kiro/` skill folders are committed **on purpose** — this is a learning project. Read them, fork them, send PRs. Everything here is meant to be studied.

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player icon" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  A native, local-first video player for <b>macOS · iOS · iPadOS</b>,<br/>
  built with SwiftUI &amp; AVFoundation and a Liquid&nbsp;Glass aesthetic.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 Project Philosophy

| | |
|---|---|
| **Native only** | No Electron, React Native, Flutter, or WebView. SwiftUI + AVFoundation. |
| **Local-first** | No accounts, no cloud sync, no online scraping. Your files stay yours. |
| **Liquid Glass** | iOS 26 / iPadOS 26 / macOS 26 materials — fluid transparency, organic blur, HIG-compliant. |
| **AI-driven workflow** | Implementation by AI, code review by humans. See `AGENTS.md`. |

---

## ✨ Features

- 🎬 **Native playback engine** — `AVPlayer` behind a clean `PlayerEngine` protocol.
- 🪟 **Liquid Glass UI** — `.glassEffect` / `.glassEffectTransition(.materialize)` on iOS 26+.
- 👆 **Touch-first iOS controls** — auto-hiding panel, scrub gesture, glass pills.
- 🔊 **System-volume bridge** — KVO + `MPVolumeView` sync, custom haptic re-creation.
- 🖥️ **Native macOS shell** — window menus and lifecycle (iPadOS-equivalent on iPad).
- 🔒 **Zero telemetry** — nothing leaves the device. Ever.

### 🚧 Roadmap

See [`TODO.md`](TODO.md) for the full plan. Highlights:

- 🐛 Volume pill not syncing when hardware keys change volume in-foreground.
- 📱 Dynamic Island avoidance for portrait-mode top pills.
- 🎛️ Gesture system: half-screen long-press speed, double-tap skip, vertical brightness / volume.
- ⚡ Speed-pill (0.5× / 1× / 2× / 3×) with Liquid-Glass selection state.
- 🎞️ Info panel — Apple-TV-style bottom overlay with thumbnail + metadata.
- 📺 PIP & AirPlay support.
- 🌀 Progress-bar physics & rubber-band feedback.

---

## 🏗 Architecture

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

Strict MVVM. Views never touch `AVPlayer`, persistence, or services directly. The single sanctioned exception is performance-sensitive gesture state (see `AGENTS.md` § Architecture).

---

## 🤖 With AI Assistants

This repo is a worked example of **AI-native development**. Everything an assistant needs to be productive on day one is checked in:

| File / Folder | Purpose |
|---|---|
| `AGENTS.md` | **Source of truth** — rules, tenets, scope discipline, workflow. |
| `CLAUDE.md` / `GEMINI.md` | Per-tool entrypoints (mostly mirrors of `AGENTS.md`). |
| `.claude/skills/`  | Project-specific Claude Code skills (`glass-know`, `hig-doctor`). |
| `.gemini/skills/`  | Gemini CLI equivalents. |
| `.kiro/skills/` `.kiro/agents/` | Kiro CLI workflows. |
| `TODO.md` | Detailed next-iteration task list with verified scope. |
| `issues-*.md` `Refer/` | Long-form context notes the assistants reference. |

**Per-user config is NOT committed.** `*.local.json`, credentials, transcripts, and ephemeral state are all gitignored. When you fork, your local toggles stay local.

> 💡 New to AI-assisted iOS development? Start by reading `AGENTS.md`, then open the repo in **any** of the listed CLIs. The skills auto-activate based on context.

---

## 🛠 Build & Run

**Requirements**

- Xcode 26 (iOS 26 / macOS 26 SDK)
- Swift 6
- macOS 26 host (for the macOS target)

**Get started**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**Build & test from the command line**

```bash
# Build
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# Test
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**Run via Claude Code + XcodeBuildMCP** (recommended for AI workflow)

```text
> /run         # launches the app on the configured simulator
> /verify      # runs the change end-to-end and reports
```

---

## 🤝 Contributing

PRs welcome — this project actively encourages **forks, experiments, and learning PRs**.

- Read `AGENTS.md` first; its scope-discipline rules apply to humans and AI alike.
- Keep changes small and focused. One commit = one logical unit.
- Build must stay green: run `xcodebuild … build` before pushing.
- Commit format: `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

Issues, discussions, and "I learned X from this repo" notes are equally welcome.

---

## 📜 License

Released under the **GNU General Public License v3.0** (GPL-3.0).

> Why GPL? This project exists to teach. GPL ensures that derivatives — including AI-generated forks — stay open so that the next learner can study them too. If you build something on top of it, share it back.

See [`LICENSE`](LICENSE) for the full text.

---

<p align="center">
  <sub>Made with <code>SwiftUI</code> + a lot of <code>/clear</code>.</sub>
</p>
