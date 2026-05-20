<!--
README-zh_cn.md — 中文版。与 README.md 内容对应，结构保持一致。
-->

<p align="right">
  <a href="README.md">English</a> ·
  <b>简体中文</b> ·
  <a href="README-zh_tw.md">繁體中文</a> ·
  <a href="README-ja.md">日本語</a> ·
  <a href="README-ko.md">한국어</a> ·
  <a href="README-ru.md">Русский</a>
</p>

> **由 AI 实现，由人类执导。**
> 本项目使用 **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI** 端到端开发。
> AI 负责编码落地，开发者扮演 **创意总监 与 测试者** 的角色。
> `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 以及 `.claude/` `.gemini/` `.kiro/` 等技能目录 **特意提交到仓库** —— 这是一个学习项目，鼓励阅读、Fork、提 PR。一切都为学习而生。

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player 图标" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  面向 <b>macOS · iOS · iPadOS</b> 的原生、本地优先视频播放器，<br/>
  基于 SwiftUI &amp; AVFoundation 与 Liquid&nbsp;Glass 设计语言构建。
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 项目理念

| | |
|---|---|
| **仅用原生 API** | 不用 Electron、React Native、Flutter 或 WebView。SwiftUI + AVFoundation。 |
| **本地优先** | 无账户、无云同步、无在线刮削。你的文件始终属于你。 |
| **Liquid Glass** | iOS 26 / iPadOS 26 / macOS 26 材质 —— 流动透明、有机模糊、严格遵循 HIG。 |
| **AI 驱动的工作流** | AI 写代码，人类做评审。详见 `AGENTS.md`。 |

---

## ✨ 已实现功能

- 🎬 **原生播放引擎** —— `AVPlayer` 隐藏在简洁的 `PlayerEngine` 协议之后。
- 🪟 **液态玻璃 UI** —— iOS 26+ 的 `.glassEffect` / `.glassEffectTransition(.materialize)`。
- 👆 **触屏优先的 iOS 控件** —— 自动隐藏面板、Scrub 手势、玻璃 pill。
- 🔊 **系统音量桥** —— KVO + `MPVolumeView` 同步，自绘 haptic 反馈。
- 🖥️ **原生 macOS 外壳** —— 窗口菜单与生命周期（iPad 等效适配）。
- 🔒 **零遥测** —— 任何数据不离开设备。从不。

### 🚧 待开发功能（Roadmap）

完整计划见 [`TODO.md`](TODO.md)。重点：

- 🐛 前台用硬件按键改音量时，音量 pill 未同步。
- 📱 竖屏顶部三个 pill 与灵动岛碰撞，需让位。
- 🎛️ 手势体系：左右半屏长按变速、双击跳秒、纵向滑动调亮度 / 音量。
- ⚡ 速度面板 pill（0.5× / 1× / 2× / 3×）+ 液态玻璃选中态。
- 🎞️ 简介面板 —— Apple TV 风格底部浮层，含缩略图与文件信息。
- 📺 PIP 画中画与 AirPlay。
- 🌀 进度条物理弹性与橡皮筋回弹。

---

## 🏗 架构

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

严格 MVVM。Views 永远不直接访问 `AVPlayer`、持久化或 Services。唯一例外是性能敏感的手势状态（详见 `AGENTS.md` § Architecture）。

---

## 🤖 关于 AI 助手

本仓库是一个 **AI 原生开发** 的工作样例。让一个 AI 助手开箱即用所需的一切都已提交：

| 文件 / 目录 | 用途 |
|---|---|
| `AGENTS.md` | **唯一事实源** —— 规则、信条、范围纪律、工作流。 |
| `CLAUDE.md` / `GEMINI.md` | 各家 CLI 的入口（大部分镜像自 `AGENTS.md`）。 |
| `.claude/skills/`  | Claude Code 项目级技能（`glass-know`、`hig-doctor`）。 |
| `.gemini/skills/`  | Gemini CLI 对应技能。 |
| `.kiro/skills/` `.kiro/agents/` | Kiro CLI 工作流。 |
| `TODO.md` | 下一轮迭代的细化任务清单。 |
| `issues-*.md` `Refer/` | AI 助手参考的长文上下文笔记。 |

**个人偏好配置不会提交。** `*.local.json`、凭证、对话记录、临时状态都已 gitignore。Fork 之后，本地切换不会污染主仓。

> 💡 第一次接触 AI 辅助 iOS 开发？先读 `AGENTS.md`，然后用上面任何一个 CLI 打开本仓库。技能会按上下文自动激活。

---

## 🛠 编译与运行

**环境要求**

- Xcode 26（iOS 26 / macOS 26 SDK）
- Swift 6
- macOS 26 主机（构建 macOS target 时）

**起步**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**命令行构建与测试**

```bash
# Build
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# Test
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**通过 Claude Code + XcodeBuildMCP 运行**（推荐的 AI 工作流）

```text
> /run         # 在当前选定的模拟器上启动 App
> /verify      # 端到端验证一次改动并汇报
```

---

## 🤝 贡献

欢迎 PR —— 本项目积极鼓励 **Fork、实验、学习型 PR**。

- 先读 `AGENTS.md`，范围纪律对人类和 AI 同等适用。
- 改动小而聚焦。一次 commit = 一个逻辑单元。
- 构建必须保持绿灯：push 前先 `xcodebuild … build`。
- Commit 格式：`^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

Issue、Discussion、以及「我从这个仓库学到了 X」的笔记，都同样欢迎。

---

## 📜 许可协议

本项目以 **GNU General Public License v3.0**（GPL-3.0）发布。

> 为什么用 GPL？这个项目是为学习而生。GPL 确保所有衍生品（包括 AI 生成的 Fork）也保持开源，下一位学习者才能继续研究下去。如果你在它之上做出了东西，请把它分享回来。

完整条款见 [`LICENSE`](LICENSE)。

---

<p align="center">
  <sub>用 <code>SwiftUI</code> 和很多 <code>/clear</code> 写成。</sub>
</p>
