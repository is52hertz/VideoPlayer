<!--
README.md — written to be both human-friendly on GitHub and learning-friendly
for AI assistants opening the repo. The HTML below renders on github.com.
-->

<p align="right">
  <a href="README.md">English</a> ·
  <a href="README-zh_cn.md">简体中文</a> ·
  <a href="README-zh_tw.md">繁體中文</a> ·
  <a href="README-ja.md">日本語</a> ·
  <b>한국어</b> ·
  <a href="README-ru.md">Русский</a>
</p>

> **AI로 만들고, 사람이 디렉팅합니다.**
> 이 프로젝트는 **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI** 로 처음부터 끝까지 개발되었습니다.
> AI가 구현을 담당하고, 개발자는 **크리에이티브 디렉터이자 QA** 역할을 합니다.
> `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, 그리고 `.claude/` `.gemini/` `.kiro/` 스킬 폴더들은 **의도적으로** 커밋되어 있습니다 — 이 프로젝트는 학습용입니다. 읽어보고, 포크하고, PR을 보내주세요. 이곳의 모든 것은 연구를 위한 것입니다.

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player icon" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  <b>macOS · iOS · iPadOS</b> 를 위한 네이티브, 로컬 우선 비디오 플레이어,<br/>
  SwiftUI &amp; AVFoundation 과 Liquid&nbsp;Glass 미학으로 구축되었습니다.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 프로젝트 철학

| | |
|---|---|
| **네이티브 전용** | Electron, React Native, Flutter, WebView 사용 안 함. SwiftUI + AVFoundation 만 사용합니다. |
| **로컬 우선** | 계정 없음, 클라우드 동기화 없음, 온라인 스크래핑 없음. 당신의 파일은 당신의 것으로 남습니다. |
| **Liquid Glass** | iOS 26 / iPadOS 26 / macOS 26 머티리얼 — 유동적인 투명도, 자연스러운 블러, HIG 준수. |
| **AI 주도 워크플로우** | 구현은 AI가, 코드 리뷰는 사람이. 자세한 내용은 `AGENTS.md` 참조. |

---

## ✨ 기능

- 🎬 **네이티브 재생 엔진** — 깔끔한 `PlayerEngine` 프로토콜 뒤의 `AVPlayer`.
- 🪟 **Liquid Glass UI** — iOS 26+ 의 `.glassEffect` / `.glassEffectTransition(.materialize)`.
- 👆 **터치 우선 iOS 컨트롤** — 자동 숨김 패널, 스크럽 제스처, 글래스 필.
- 🔊 **시스템 볼륨 브리지** — KVO + `MPVolumeView` 동기화, 커스텀 햅틱 재현.
- 🖥️ **네이티브 macOS 셸** — 윈도우 메뉴와 라이프사이클 (iPad 에서는 iPadOS 동등).
- 🔒 **제로 텔레메트리** — 디바이스를 벗어나는 데이터 없음. 절대로.

### 🚧 로드맵

전체 계획은 [`TODO.md`](TODO.md) 를 참조하세요. 주요 항목:

- 🐛 포어그라운드에서 하드웨어 키로 볼륨을 변경할 때 볼륨 필이 동기화되지 않는 문제.
- 📱 세로 모드 상단 필의 Dynamic Island 회피.
- 🎛️ 제스처 시스템: 반화면 롱프레스 속도, 더블탭 스킵, 수직 밝기 / 볼륨.
- ⚡ Liquid-Glass 선택 상태가 적용된 속도 필 (0.5× / 1× / 2× / 3×).
- 🎞️ 정보 패널 — 썸네일 + 메타데이터가 포함된 Apple-TV 스타일 하단 오버레이.
- 📺 PIP 및 AirPlay 지원.
- 🌀 진행 바 물리 효과 및 러버 밴드 피드백.

---

## 🏗 아키텍처

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

엄격한 MVVM. View 는 `AVPlayer`, 영속성, 서비스에 직접 접근하지 않습니다. 유일하게 허용되는 예외는 성능에 민감한 제스처 상태입니다 (`AGENTS.md` § Architecture 참조).

---

## 🤖 AI 어시스턴트와 함께

이 저장소는 **AI 네이티브 개발** 의 실전 예시입니다. 어시스턴트가 첫날부터 생산성을 발휘하는 데 필요한 모든 것이 커밋되어 있습니다:

| 파일 / 폴더 | 용도 |
|---|---|
| `AGENTS.md` | **단일 진실 공급원 (Source of truth)** — 규칙, 원칙, 스코프 규율, 워크플로우. |
| `CLAUDE.md` / `GEMINI.md` | 도구별 진입점 (대부분 `AGENTS.md` 의 미러). |
| `.claude/skills/`  | 프로젝트 전용 Claude Code 스킬 (`glass-know`, `hig-doctor`). |
| `.gemini/skills/`  | Gemini CLI 동등 버전. |
| `.kiro/skills/` `.kiro/agents/` | Kiro CLI 워크플로우. |
| `TODO.md` | 검증된 스코프와 함께 다음 이터레이션의 상세 작업 목록. |
| `issues-*.md` `Refer/` | 어시스턴트가 참조하는 장문 컨텍스트 노트. |

**사용자별 설정은 커밋되지 않습니다.** `*.local.json`, 자격 증명, 트랜스크립트, 임시 상태는 모두 gitignore 처리되어 있습니다. 포크할 때 로컬 토글은 로컬에 머무릅니다.

> 💡 AI 보조 iOS 개발이 처음이신가요? `AGENTS.md` 를 먼저 읽고, 위에 나열된 **아무** CLI 에서나 저장소를 여세요. 스킬은 컨텍스트에 따라 자동 활성화됩니다.

---

## 🛠 빌드 & 실행

**요구 사항**

- Xcode 26 (iOS 26 / macOS 26 SDK)
- Swift 6
- macOS 26 호스트 (macOS 타겟용)

**시작하기**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**커맨드 라인에서 빌드 & 테스트**

```bash
# 빌드
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# 테스트
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**Claude Code + XcodeBuildMCP 로 실행** (AI 워크플로우에 권장)

```text
> /run         # 설정된 시뮬레이터에서 앱을 실행합니다
> /verify      # 변경 사항을 엔드 투 엔드로 실행하고 보고합니다
```

---

## 🤝 컨트리뷰팅

PR 환영합니다 — 이 프로젝트는 **포크, 실험, 학습 목적의 PR** 을 적극 권장합니다.

- `AGENTS.md` 를 먼저 읽어 주세요. 스코프 규율 규칙은 사람과 AI 모두에게 적용됩니다.
- 변경은 작고 집중적으로 유지하세요. 하나의 커밋 = 하나의 논리적 단위.
- 빌드는 항상 그린이어야 합니다: 푸시 전에 `xcodebuild … build` 를 실행하세요.
- 커밋 포맷: `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

이슈, 토론, 그리고 "이 저장소에서 X 를 배웠습니다" 같은 노트도 똑같이 환영합니다.

---

## 📜 라이선스

**GNU General Public License v3.0** (GPL-3.0) 하에 공개됩니다.

> 왜 GPL인가요? 이 프로젝트는 가르치기 위해 존재합니다. GPL 은 파생물 — AI가 생성한 포크를 포함하여 — 이 계속 공개되도록 보장하여, 다음 학습자도 그것을 연구할 수 있게 합니다. 이 위에 무언가를 만든다면, 다시 공유해 주세요.

전체 텍스트는 [`LICENSE`](LICENSE) 를 참조하세요.

---

<p align="center">
  <sub><code>SwiftUI</code> 와 수많은 <code>/clear</code> 로 만들었습니다.</sub>
</p>
