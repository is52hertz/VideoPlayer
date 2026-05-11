---
name: hig-doctor
description: Apple Human Interface Guidelines (HIG) reviewer for macOS, iOS, and iPadOS. Use this skill to audit UI/UX against Apple standards for the VideoPlayer project (SwiftUI + AVFoundation). It covers layout, materials, motion, and control conventions.
---

# HIG Doctor: Apple Design Reviewer

Use this skill to ensure the VideoPlayer app adheres to Apple's Human Interface Guidelines across macOS, iOS, and iPadOS.

## Core Focus Areas

- **Immersive Video Playback**: Principles for distraction-free viewing and organic control surfacing.
- **Platform Adaptation**: Transitioning between pointer/keyboard (macOS), touch (iOS), and hybrid (iPadOS) inputs.
- **Materials & Effects**: Proper use of vibrancy, blur, and "Liquid Glass" aesthetics within the Apple ecosystem.
- **Controls & Interaction**: HIG-compliant sliders, buttons, and gestures for media playback.

## Reference Index

| Reference | Topic | When to use |
|---|---|---|
| [macos.md](references/macos.md) | macOS Design | Reviewing window management, menu bars, and pointer interactions. |
| [ios_ipados.md](references/ios_ipados.md) | iOS & iPadOS Design | Reviewing touch targets, multitasking, and handheld ergonomics. |
| [media-controls.md](references/media-controls.md) | Media Controls | Reviewing play/pause, sliders, and playback-specific UI patterns. |
| [foundations.md](references/foundations.md) | Visual Foundations | Reviewing materials (vibrancy), motion, and accessibility. |

## Review Workflow

1. **Context Check**: Identify the target platform and input method.
2. **Visual Audit**: Evaluate materials, hierarchy, and adherence to "Liquid Glass" principles.
3. **Interactive Audit**: Test gestures, keyboard shortcuts (macOS), and control accessibility.
4. **Platform Specifics**: Ensure macOS feels like a desktop app and iOS feels like a mobile app.

## Related Conventions (VedioPlayer)

- **Liquid Glass**: Fluid transparency and organic blur effects.
- **View → ViewModel → Engine**: Keep UI logic separated from playback engine.

---
*Adapted for VedioPlayer project.*
