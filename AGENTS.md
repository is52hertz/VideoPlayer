# AGENTS.md — SSOT
> Authoritative rules for all AI agents in this repo.

This file is the single source of truth for every AI coding assistant working on this project. Tool-specific files (`CLAUDE.md`, `GEMINI.md`) point here.

Keep it to durable, cross-session guidance — product, rules, standards, security, handoff. Session scratch (current branch, this round's progress, temporary state) does not belong here; put it in the End-of-Session Summary or `notice.md`.

---

## Instruction Priority

- Treat this `AGENTS.md` as the authority for product requirements, business rules, coding standards, security/correctness constraints, verification expectations, commit policy, and handoff rules.
- Treat Trellis as the authority for task workflow mechanics: task lifecycle, phase order, PRD/research/spec-context handling, quality-gate sequence, session journal, and finish/archive steps.
- When these instructions and Trellis overlap, apply the more specific authority: product/business/code/security rules from `AGENTS.md`; task lifecycle and phase-flow rules from Trellis.
- Do not use Trellis text to weaken or bypass the business, security, correctness, or scope rules in this file.
- Do not use this file as a reason to skip required Trellis steps unless the current user message explicitly opts out for that turn.

---

## Product

A local-first video player. The user opens a file from their own disk and watches it — single user, no server, no account, no network. One SwiftUI codebase ships a macOS app and an iOS/iPadOS app.

| | |
|---|---|
| **Platforms** | macOS · iOS · iPadOS |
| **Stack** | SwiftUI · AVFoundation/AVKit · SwiftData |
| **Architecture** | View → ViewModel → PlayerEngine → AVPlayer |
| **Design** | Liquid Glass — fluid transparency, organic blur, HIG-first |
| **Naming** | `VideoPlayer` (identifier) / `Video Player` (display) |

**Hard constraints:** Native Apple APIs only. No Electron/RN/Flutter/WebView. No accounts, cloud sync, or online scraping.

## Project Phase

> Terse, kept-current snapshot. Update in place; don't append history.

- **VideoPlayer (app)**: playback works on all three platforms — `PlayerEngine` protocol with `AVPlayerEngine`, `PlayerViewModel`, Glass-based player controls, `AudioSessionManager` / `SystemVolumeManager` in `Services/`. SwiftData is in use: `@Model RecentVideo` persisted via `.modelContainer(for:)`.
- **Tests**: `VideoPlayerTests` / `VideoPlayerUITests` are still default Xcode scaffolding (`@Test func example()` is empty). `Engine/` and `ViewModel/` have no real coverage.
- **AI subtitle / transcription**: not built.
- **Project specs (`.trellis/spec/`)**: still the generic web-oriented templates (`frontend/`, `backend/`, hooks, database) — not authored for Swift. Task `00-bootstrap-guidelines` covers this.

---

## Core Tenets

- Prefer smaller, more native, more restrained implementations.
- Avoid premature abstraction, singletons, large view bodies, unrelated changes in one pass.
- Local-first. Never upload video/audio/subtitles/filenames/metadata without explicit approval.
- Keep the build green after every meaningful change.

---

## Development Rules

Concrete, project-specific coding standards live in **Unified Guidelines** below; they take precedence over generic advice from any skill, plugin, or spec template.

### Communication Language
- User-facing output — explanations, questions, status updates, summaries, anything the user reads — must be in Simplified Chinese (简体中文).
- Software and internal work stays in English: code, identifiers, comments, commit messages, logs, test names, and your own reasoning/analysis.
- This governs presentation, not content: do not rename existing identifiers or rewrite existing English docs just to comply, and match the surrounding language of any file you edit.

### Two-Step Confirmation First
- Never start the moment a requirement is stated or changed. Every new or modified requirement first passes through an understand-and-confirm step before any code is written. The only exception is trivial mechanical actions whose intent is obvious (e.g. `git push`, fixing a typo, a one-line rename).
- **Step one — reflect and surface, always in the open before building:**
  - Judge whether the request is sound: is it safe? is it efficient? does it fit the project's scale?
  - Consider whether a better approach exists than the one asked for.
  - State your full understanding of the request, your analysis of it (risks, tradeoffs, anything ill-advised), and your concrete recommendation.
- **Step two — act on the outcome:**
  - If the request is uncertain (multiple approaches with tradeoffs, may affect other features, or ill-suited to the project's scale), wait for the user's confirmation before modifying code.
  - If there is a clearly optimal and safe path, you may proceed without waiting for confirmation — but conspicuously notify the user that you are doing so up front, and on completion state plainly what you changed and why it was the better path.
  - Push back on any request that compromises security, correctness, or runtime efficiency, even when explicitly asked.
- This gate is about *starting* work. Once work is approved and the build is green, commit without a further handoff — see **Verify & Commit**.

### Dry-Run Requests
- When the user's prompt contains "dry-run", treat the request as read-only: do not modify code, files, or configuration.
- Respond with two things: (1) your complete understanding of the request, and (2) a detailed, step-by-step explanation of how you would execute it.
- Make changes only after the user explicitly asks you to proceed.

### Simplicity First
- Write the minimum code that solves the stated problem; nothing speculative.
- No features, flags, config, or abstractions that weren't requested. Don't build "flexibility" for a future that isn't here.
- A single-use helper needs no abstraction — inline first, extract only on the second real caller.
- Validate untrusted input at the trust boundary, but don't add defensive handling for inputs that cannot occur.
- Adding a new third-party dependency needs the user's OK first; prefer the standard library and what's already in the project, and say why the dep is worth its cost.
- Before finishing, ask: would a senior engineer call this overcomplicated? If yes, cut it down.

### Scope Discipline
- Stay within the requested change. No opportunistic refactor, rename, or "tidy up" of adjacent code.
- Spotted a related issue? **Surface it to the user first.** Do not silently fix.
- If the current task logically depends on another unbuilt feature, ask the user before implementing it. Never silently introduce adjacent functionality.
- Match the surrounding style and patterns even if you'd do it differently; don't reformat or refactor code your task doesn't touch.
- Clean up only the orphans your change creates (now-unused imports/vars/functions). Pre-existing dead code: flag it, don't delete it.
- One commit = one logical unit. No drive-by edits.

### Secrets & Sensitive Data
- Never hardcode secrets or credentials; read them from environment/config. Never print, log, or echo secrets, tokens, or PII.
- Keep the project's seeded secrets-deny rules (covering `.env*`, `secrets/**`, and key files) in place.

### Verify & Commit
- Before coding, restate the task as a concrete, checkable success criterion rather than "make it work", and scale testing to the work's risk.
- **Build after every change round.** Never proceed or commit on a broken build.
  - Build: `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build`
  - Test:  `xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test`
- If verification fails, fix the errors first, then verify again.
- **Auto-commit on green build.** As soon as `xcodebuild` succeeds, commit the logical unit. Do NOT wait for the user to manually verify in the simulator before committing — the user reviews via git history, not via blocking handoff. Never commit mid-refactor or on a broken build.
- Before committing, inspect dirty files and separate current-task agent edits from unrecognized dirty files. Do not include unrecognized dirty files in commits unless the user explicitly asks to include them.
- If a dirty file's ownership or task relevance cannot be determined safely, stop and ask the user before committing.
- Group commits by coherent change unit. Do not push unless explicitly requested.
- **Branching:** feature and experimental work goes on its own branch off the mainline. This repo uses descriptive prefixes as they fit the work (`feature/`, `refactor/`, `try/`, `snap-`) rather than one mandated form. Keep merged branches as historical archives — never delete them, local or remote.
- **Commit message format** (Conventional Commits, scope optional):

  ```
  type(scope): short summary

  Detailed description of what changed and why.
  ```

  Types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `ci`, `perf`.
  Scope is optional and conventionally the platform or area (`ios`, `macOS`, `settings`). A body is optional but expected for anything non-obvious.

### Project Profile

**Profile: client app** — a local-first SwiftUI application for macOS/iOS/iPadOS. No server, no network, no accounts.

- **Trust boundary** is the local filesystem and the user's own media. Validate what comes off disk — unreadable files, unsupported codecs, revoked security-scoped bookmarks — and fail visibly rather than crashing. There is no untrusted remote caller to defend against.
- **Never** add network calls, telemetry, analytics, or crash reporting. Never upload video/audio/subtitles/filenames/metadata.
- **Testing scales to risk:**
  - `Engine/` · `ViewModel/` · `Services/` · `Models/` — unit tests required; run `test_sim`, then check `get_coverage_report` / `get_file_coverage`.
  - Pure view/layout/material work — a green build plus a simulator or device pass is enough. Don't build a test harness for pixel work.
  - For a bug, add the failing test first, then make it pass.
- **Keep the layering.** MVVM and the `PlayerEngine` protocol are load-bearing here — this is not a throwaway script, so do not "simplify" by collapsing layers. Simplicity First applies *within* a layer, not across the architecture.

### Session Handoff
- `notice.md` files are scoped by directory and record durable handoff information for the next agent.
- At the start of a task, read the relevant `notice.md` files (the root one and those in the directories you'll work in) before making changes.
- Root `notice.md` records global, cross-package, or cross-task project information.
- App/package notices record durable facts for that app/package: architecture, contracts, workflows, credentials, known limitations, and package-specific gotchas.
- Update the relevant `notice.md` only when the session creates or discovers information that remains useful beyond the current task or conversation. Do not record pure Q&A, routine progress, temporary decisions, or workflow session/journal details there.
- Ensure any `notice.md` you touch remains accurate and up-to-date within its directory scope.

### End-of-Session Summary
- At the end of each conversation, output a brief summary in 中文 (Chinese). This summary is user-facing.
  ```
  ## Summary
  - **Done**: work completed this round
  - **Key decisions**: tag each [user] or [self], explain the decision
  - **Commits**: list this round's commits (hash, message, files); note any dirty files left out and why
  - **Open/known risks**: issues introduced or discovered this round (omit if none)
  - **Suggested next steps**: 1-3 concrete actionable items
  ```

---

## Unified Guidelines

### Architecture
- **MVVM, preferred.** View → ViewModel → PlayerEngine → AVPlayer.
  - Mutable state, IO, async work, side effects → `@Observable` ViewModels or Services. Avoid in View bodies or `.onAppear` by default.
  - Views invoke intents (`vm.togglePlayback()`); no direct access to `AVPlayer`, persistence, or services.
  - Do **not** adopt SwiftUI "MV-style" (state on View, services injected into the body), even if `apple-skills` suggests it.
  - **Exception 1:** stateless presentation primitives (`GlassButton`, `VisualEffectBackground`, etc.) need no VM.
  - **Exception 2 — performance:** MVVM may be relaxed when strict adherence demonstrably hurts performance (e.g. high-frequency gesture state that would otherwise churn `@Observable` and cascade view invalidations). Keep such View-local state minimal, comment *why* it lives in the View, and still route the resulting intent (`seek`, `setVolume`, …) through the ViewModel. MVVM is the default; performance is the only sanctioned reason to deviate.
- **Source of truth & persistence.** Playback state is owned by `PlayerEngine` and surfaced through `PlayerViewModel`; other mutable state lives in `@Observable` ViewModels. Durable state is SwiftData (`@Model`, e.g. `RecentVideo`) reached through the SwiftUI model container — the project currently has no `UserDefaults` / `@AppStorage` / ad-hoc file store, and shouldn't grow one alongside SwiftData without a reason.
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
- **Significant UI changes** (new screen, major layout, new interactive component): `build_run_sim` (launch simulator for manual testing only). No screenshot/interact unless user requests — player UI requires a loaded video file. HIG Doctor: code review, not screenshot-driven. Skip color/spacing/copy tweaks.

<!-- TRELLIS:START -->
# Trellis Instructions

These instructions are for AI assistants working in this project.

This project is managed by Trellis. The working knowledge you need lives under `.trellis/`:

- `.trellis/workflow.md` — development phases, when to create tasks, skill routing
- `.trellis/spec/` — package- and layer-scoped coding guidelines (read before writing code in a given layer)
- `.trellis/workspace/` — per-developer journals and session traces
- `.trellis/tasks/` — active and archived tasks (PRDs, research, jsonl context)

If a Trellis command is available on your platform (e.g. `/trellis:finish-work`, `/trellis:continue`), prefer it over manual steps. Not every platform exposes every command.

If you're using Codex or another agent-capable tool, additional project-scoped helpers may live in:
- `.agents/skills/` — reusable Trellis skills
- `.codex/agents/` — optional custom subagents

Managed by Trellis. Edits outside this block are preserved; edits inside may be overwritten by a future `trellis update`.

<!-- TRELLIS:END -->
