# CLAUDE.md

## Role

You are the coding agent for a native Apple-platform video player.

Your job is to keep the project small, native, elegant, and maintainable.

## Product Direction

Build a HIG-first video player for:

- iOS
- iPadOS
- macOS

Core qualities:

- Native SwiftUI experience
- Minimal player chrome
- Beautiful glass-style controls
- Automatic subtitle generation
- Playback speed control
- Local-first privacy

## Hard Constraints

Use:

- SwiftUI
- AVFoundation / AVKit
- SwiftData where persistence is needed
- Native Apple APIs

Do not use:

- Electron
- React Native
- Flutter
- WebView UI
- Account system
- Cloud sync
- Online media scraping
- Non-MVP feature creep

## Design Principles

- Video content is the primary surface.
- Controls should appear only when needed.
- UI must feel Apple-native, quiet, restrained, and precise.
- Liquid Glass / material effects must be subtle.
- Avoid decorative animation.
- Avoid visual noise.
- Avoid dashboard-style layouts.
- Avoid overusing blur, glow, gradients, or shadows.

## Architecture Principles

Keep clear separation between:

- Playback
- Subtitle logic
- AI transcription
- Media file access
- Persistence
- Design system
- Feature views

Feature views must not contain raw styling everywhere.

Reusable UI primitives should own visual treatment:

- `GlassPanel`
- `GlassButton`
- `GlassToolbar`
- `GlassSlider`
- `GlassPopover`

Do not scatter modifiers like this across feature files:

```swift
.background(.ultraThinMaterial)
.shadow(...)
.cornerRadius(...)
.blur(...)
```

## Playback Rule

Playback logic must be isolated behind an engine/protocol.

Views should not directly manage complex `AVPlayer` state.

Preferred flow:

```txt
View
→ ViewModel
→ PlayerEngine
→ AVPlayer-based implementation
```

## Subtitle Rule

Subtitle loading, parsing, timing lookup, and generation must be separate from playback.

Support subtitle logic as independent services.

AI subtitle generation should start as a replaceable service, not hardcoded inside UI.

## Coding Rules

* Make small changes.
* Keep files focused.
* Prefer native APIs.
* Avoid premature abstraction.
* Avoid singletons unless unavoidable.
* Avoid large view bodies.
* Avoid unrelated changes in one pass.
* Prefer readable code over clever code.
* Keep the app compiling after each meaningful change.

## Platform Rules

macOS should feel like macOS.

iOS/iPadOS should feel immersive and touch-first.

Use platform-specific code only when it improves the experience.

## Privacy Rule

Automatic subtitles should be local-first.

Do not upload video, audio, subtitles, filenames, or metadata without explicit approval.

## Review Checklist

Before finishing any task, check:

* Does it compile?
* Is the change inside the requested scope?
* Does the UI still feel native?
* Is video still visually dominant?
* Is styling centralized?
* Did we avoid feature creep?
* Did we avoid unnecessary dependencies?
* Is the implementation easy to revise later?

## Default Decision Rule

When uncertain, choose the smaller, more native, more restrained implementation.
