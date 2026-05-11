# VideoPlayer Project Guide

This project is a native Apple-platform video player built with SwiftUI and AVFoundation. It focuses on a minimalist, HIG-adherent "glass-style" UI.

## Project Overview

- **Core Goal:** Build a small, native, elegant, and maintainable video player for iOS, iPadOS, and macOS.
- **Tech Stack:** SwiftUI, AVFoundation/AVKit, SwiftData (planned).
- **Hard Constraints:** 
  - Use ONLY native Apple APIs.
  - NO Electron, React Native, Flutter, or WebView UI.
  - NO account systems or cloud sync.
- **Privacy:** Local-first. Automatic subtitles and metadata must be processed locally.

## Architecture & Principles

### 1. The Playback Rule (View → ViewModel → Engine)
- **Isolation:** Playback logic MUST be isolated behind the `PlayerEngine` protocol.
- **Flow:** Views should never manage `AVPlayer` state directly.
- **Engine Implementation:** `AVPlayerEngine` handles the low-level `AVPlayer` and observation logic.

### 2. Design System (Liquid Glass)
- **Core Aesthetic:** Strictly follow Apple HIG while implementing a "Liquid Glass" (液态玻璃) style. This means using dynamic, fluid transparency and organic blur effects that feel native yet modern.
- **Primary Surface:** Video content is the focus. Controls appear only when needed, emerging from the liquid background.
- **Centralized Styling:** Reusable UI primitives (`GlassPanel`, `GlassButton`, `GlassSlider`) own the visual treatment.
- **No Scattered Modifiers:** Avoid repeating complex material and shadow modifiers in feature views; keep all "liquid" effects centralized.

### 3. Subtitle Logic
- Subtitle loading, parsing, and timing must be independent services, separate from playback and UI.

## Development Conventions

- **State Management:** Use the `@Observable` macro. Logic resides in ViewModels or Services.
- **Coding Style:**
  - Small, focused files.
  - Prefer readable code over "clever" code.
  - Keep the app compiling after every meaningful change.
- **Platform Rules:** 
  - macOS should feel like macOS (proper windowing, menus).
  - iOS/iPadOS should be touch-first and immersive.
- **Naming:** Note the project-wide spelling of `VedioPlayer`.

## Building and Running

### Requirements
- **Xcode 15+**, **macOS 14+**.

### Key Commands
- **Build:** `xcodebuild -project VedioPlayer.xcodeproj -scheme VedioPlayer build`
- **Test:** `xcodebuild -project VedioPlayer.xcodeproj -scheme VedioPlayer test`

## Review Checklist
- [ ] Does it compile?
- [ ] Is the UI still native and HIG-compliant?
- [ ] Is video still the visually dominant surface?
- [ ] Is styling centralized in `Glass` components?
- [ ] Are there unnecessary dependencies?

## Git Workflow
- **Commit Format:** `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`
- **Rule:** Remind the user to commit at the end of meaningful task rounds.

## Default Decision Rule
When uncertain, choose the **smaller, more native, and more restrained** implementation.
