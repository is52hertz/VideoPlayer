# AGENTS.md — SSOT
> Single source of truth for all AI agents working in this repo.

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

- Ship product. Prefer smaller, more native, more restrained implementations.
- Avoid premature abstraction, singletons, large view bodies, and unrelated changes in one pass.
- Local-first privacy. Never upload video, audio, subtitles, filenames, or metadata without explicit approval.
- Keep the app compiling after every meaningful change.

---

## Scope Discipline

- Stay strictly within the requested change. Do not opportunistically refactor, rename, or "tidy up" adjacent code.
- If you spot a related issue, **surface it to the user first** — do not silently fix it in the same pass.
- One commit = one logical unit. No drive-by edits riding along.

---

## Workflow

- **Build after every round of code changes.** Do not proceed or commit on a broken build.
  - Build: `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build`
  - Test:  `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test`
- **Commit format:** `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`
- **Auto-commit** when a logical unit lands — do not wait for a reminder, do not commit mid-refactor.

---

## Unified Guidelines

### Architecture
- Isolate playback behind `PlayerEngine` protocol. Views never touch `AVPlayer` directly.
- Separate concerns strictly: Playback · Subtitle logic · AI transcription · Media access · Persistence · Design system · Feature views.
- AI subtitle generation = replaceable service, not hardcoded in UI.

### Design System
- Video content is the primary surface. Controls appear only when needed.
- Centralize all "liquid" effects in Glass primitives: `GlassPanel` · `GlassButton` · `GlassSlider` · `GlassToolbar` · `GlassPopover`. Never scatter `.background(.ultraThinMaterial)` / `.shadow()` / `.blur()` across feature views.
- Welcome and Player keep **separated** visual languages — they share Glass primitives at the base layer but their compositions must not couple.
- No decorative animation, visual noise, or dashboard-style layouts.

### Code
- Small, focused files. Readable over clever.
- `@Observable` macro for state. Logic lives in ViewModels/Services.
- macOS: proper windowing and menus. iOS/iPadOS: touch-first and immersive.

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
Trigger on Views, Glass primitives, layout, materials, motion, gestures, controls. Skip for non-UI tasks.
- **Primary checklist (all agents):** the in-repo `hig-doctor` skill — project-localized HIG review with VideoPlayer-specific references. Lives at `.claude/skills/hig-doctor/`, `.gemini/skills/hig-doctor/`, `.kiro/skills/hig-doctor/`.
- **Deeper lookups (Claude Code only):** `apple-skills:hig` for HIG reference docs, `apple-skills:ios-design-consultant` for design judgment calls, `apple-skills:ios-ui-craft` when authoring a new screen from scratch.

### When to Reach for MCP Tools
- **Playback / ViewModel state bugs:** prefer LLDB (`debug_attach_sim` …) over `print`.
- **`Engine/` or `ViewModel/` changes:** run `test_sim`, then check `get_coverage_report` / `get_file_coverage`.
- **Significant UI changes** (new screen, major layout, new interactive component): `build_run_sim` → `screenshot` → exercise → `screenshot`, then run HIG Doctor on screenshots. Skip for color/spacing/copy tweaks.
