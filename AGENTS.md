# AGENTS.md — SSOT
> Single source of truth for all AI agents. GEMINI.md and CLAUDE.md are superseded by this file.

---

## Project Pulse

| | |
|---|---|
| **Platforms** | macOS · iOS · iPadOS |
| **Stack** | SwiftUI · AVFoundation/AVKit · SwiftData (planned) |
| **Architecture** | View → ViewModel → PlayerEngine → AVPlayer |
| **Design** | Liquid Glass — fluid transparency, organic blur, HIG-first |
| **Spelling** | Project name is `VedioPlayer` (intentional) |

**Hard constraints:** Native Apple APIs only. No Electron/RN/Flutter/WebView. No accounts, cloud sync, or online scraping.

---

## Core Tenets

- Ship product. Prefer smaller, more native, more restrained implementations.
- Avoid premature abstraction, singletons, large view bodies, and unrelated changes in one pass.
- Local-first privacy. Never upload video, audio, subtitles, filenames, or metadata without explicit approval.
- Keep the app compiling after every meaningful change.

---

## Agent Protocol

**All agents:**
- Read this file before starting any task.
- Follow the Unified Guidelines below without exception.
- Follow the Git Workflow section below — commits are mandatory, not optional.

**Gemini CLI:** Primary agent. Owns proactive commits and workflow automation.

**Claude / Kiro / others:** Peer agents. Same rules apply. Defer to this file on any conflict with agent-specific config.

**HIG Doctor** — auto-invoke on any UI/UX change (Views, Glass primitives, layout, materials, motion, gestures, controls). Skip for non-UI tasks.

---

## Build Workflow

- **Build check:** After every round of code changes, run Key Commands. Do not proceed or commit if the build fails.

### Key Commands
- **Build:** `xcodebuild -project VedioPlayer.xcodeproj -scheme VedioPlayer build`
- **Test:** `xcodebuild -project VedioPlayer.xcodeproj -scheme VedioPlayer test`

---

## Git Workflow

- **Format:** `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`
- **Auto-commit:** After each round of meaningful changes or at task end, stage and commit immediately — do not wait for a manual reminder.
- **Judgment:** Commit when a logical unit of work is complete. Do not commit mid-refactor or on partial changes.

---

## Unified Guidelines

### Architecture
- Isolate playback behind `PlayerEngine` protocol. Views never touch `AVPlayer` directly.
- Separate concerns strictly: Playback · Subtitle logic · AI transcription · Media access · Persistence · Design system · Feature views.
- AI subtitle generation = replaceable service, not hardcoded in UI.

### Design System
- Video content is the primary surface. Controls appear only when needed.
- Centralize all "liquid" effects in Glass primitives: `GlassPanel` · `GlassButton` · `GlassSlider` · `GlassToolbar` · `GlassPopover`.
- Never scatter `.background(.ultraThinMaterial)` / `.shadow()` / `.blur()` across feature views.
- Welcome and Player interfaces maintain **separated** style definitions — do not couple them.
- No decorative animation, visual noise, or dashboard-style layouts.

### Code
- Small, focused files. Prefer readable over clever.
- Use `@Observable` macro for state. Logic in ViewModels/Services.
- macOS: proper windowing and menus. iOS/iPadOS: touch-first and immersive.

### Review Checklist
- [ ] Compiles?
- [ ] Change is inside requested scope?
- [ ] UI feels native and HIG-compliant?
- [ ] Video is visually dominant?
- [ ] Styling is centralized in Glass components?
- [ ] No feature creep or unnecessary dependencies?
- [ ] Easy to revise later?

### LLDB Debugging
When diagnosing playback bugs or ViewModel state issues, prefer LLDB over print statements:
1. `debug_attach_sim` — attach to running app
2. `debug_breakpoint_add` — break at suspect call site
3. `debug_variables` / `debug_stack` — inspect state
4. `debug_continue` → `debug_detach` when done

### Test Coverage
After changes to `Engine/` or `ViewModel/`, run tests and check coverage:
1. `test_sim` — run test suite
2. `get_coverage_report` — per-target summary
3. `get_file_coverage` — function-level gaps on changed files

### UI Validation
Trigger: **auto** on significant UI changes (new screen, major layout, new interactive component); **manual** only when user explicitly requests. Skip for minor tweaks (color, spacing, copy).

1. `build_run_sim` — build and launch
2. `screenshot` — capture initial state
3. `snapshot_ui` — inspect view hierarchy and coordinates
4. `tap` / `swipe` / `type_text` — exercise key interactions
5. `screenshot` — verify result
6. Run HIG Doctor review on screenshots
