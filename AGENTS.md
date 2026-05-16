# AGENTS.md — SSOT
> Authoritative rules for all AI agents in this repo.

---

## Project Pulse

| | |
|---|---|
| **Platforms** | macOS · iOS · iPadOS |
| **Stack** | SwiftUI · AVFoundation/AVKit · SwiftData (planned) |
| **Architecture** | View → ViewModel → PlayerEngine → AVPlayer |
| **Design** | Liquid Glass — fluid transparency, organic blur, HIG-first |
| **Naming** | `VideoPlayer` (identifier) / `Video Player` (display) |

**Hard constraints:** Native Apple APIs only. No Electron/RN/Flutter/WebView. No accounts, cloud sync, or online scraping.

---

## Core Tenets

- Prefer smaller, more native, more restrained implementations.
- Avoid premature abstraction, singletons, large view bodies, unrelated changes in one pass.
- Local-first. Never upload video/audio/subtitles/filenames/metadata without explicit approval.
- Keep the build green after every meaningful change.

---

## Scope Discipline

- Stay within the requested change. No opportunistic refactor, rename, or "tidy up" of adjacent code.
- Spotted a related issue? **Surface it to the user first.** Do not silently fix.
- One commit = one logical unit. No drive-by edits.

---

## Workflow

- **Build after every change round.** Never proceed or commit on a broken build.
  - Build: `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build`
  - Test:  `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test`
- **Commit format:** `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`
- **Auto-commit** each logical unit. No reminders needed. Never commit mid-refactor.

---

## Unified Guidelines

### Architecture
- **MVVM, strict.** View → ViewModel → PlayerEngine → AVPlayer.
  - Mutable state, IO, async work, side effects → `@Observable` ViewModels or Services. Never in View bodies or `.onAppear`.
  - Views invoke intents (`vm.togglePlayback()`); no direct access to `AVPlayer`, persistence, or services.
  - Do **not** adopt SwiftUI "MV-style" (state on View, services injected into the body), even if `apple-skills` suggests it.
  - **Exception:** stateless presentation primitives (`GlassButton`, `VisualEffectBackground`, etc.) need no VM.
- Playback isolated behind `PlayerEngine` protocol.
- Concern boundaries: Playback · Subtitle · AI transcription · Media access · Persistence · Design system · Feature views.
- AI subtitle = replaceable service. Never hardcode in UI.

### Design System
- Video is the primary surface. Controls surface only on demand.
- All "liquid" effects centralized in Glass primitives: `GlassPanel` · `GlassButton` · `GlassSlider` · `GlassToolbar` · `GlassPopover`. Never scatter `.background(.ultraThinMaterial)` / `.shadow()` / `.blur()` in feature views.
- Welcome ≠ Player visual language. Share Glass primitives only; do not couple compositions.
- No decorative animation, visual noise, or dashboard layouts.

### Code
- Small, focused files. Readable over clever.
- `@Observable` for state. Logic in ViewModels/Services.
- macOS: native windowing + menus. iOS/iPadOS: touch-first, immersive.

### Review Checklist
- [ ] Inside requested scope?
- [ ] UI feels native and HIG-compliant?
- [ ] Video is visually dominant?
- [ ] No feature creep or unnecessary dependencies?
- [ ] Easy to revise later?

---

## Agent Tooling

> Short names below map to **XcodeBuildMCP** tools (e.g. `test_sim` → `mcp__XcodeBuildMCP__test_sim`).

### HIG Doctor — auto-invoke on UI/UX changes
Trigger: Views, Glass primitives, layout, materials, motion, gestures, controls. Skip non-UI work.
- **Primary (all agents):** in-repo `hig-doctor` skill at `.claude/skills/hig-doctor/` · `.gemini/skills/hig-doctor/` · `.kiro/skills/hig-doctor/`.
- **Deeper lookups (Claude Code only):** `apple-skills:hig` (HIG ref docs) · `apple-skills:ios-design-consultant` (design decisions) · `apple-skills:ios-ui-craft` (new screen authoring).

### MCP Tool Triggers
- **Playback / ViewModel bugs:** LLDB (`debug_attach_sim` …) over `print`.
- **`Engine/` or `ViewModel/` changes:** `test_sim` → `get_coverage_report` / `get_file_coverage`.
- **Significant UI changes** (new screen, major layout, new interactive component): `build_run_sim` → `screenshot` → interact → `screenshot` → HIG Doctor on screenshots. Skip color/spacing/copy tweaks.
