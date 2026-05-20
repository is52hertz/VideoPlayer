---
name: glass-know
description: Authoritative knowledge for implementing Apple Liquid Glass (iOS 26 / iPadOS 26 / macOS 26 / tvOS 26 / watchOS 26) in this SwiftUI VideoPlayer project. Use whenever the user mentions "液态玻璃", "Liquid Glass", `.glassEffect`, `glassEffectTransition`, `GlassEffectContainer`, `.materialize`, `glass` buttons, or designs HUD / control surfaces that show, hide, or transition glass materials. Trigger this skill any time the work involves how glass should appear, dissipate, refract, blur, or interact with content underneath — even if the user only describes the *feel* (e.g. "释放", "消散", "drop into place", "Apple TV style"). Verified against iOS 26 SDK swiftinterface and the project's hands-on iteration on the player controls.
---

# Glass Know — Liquid Glass implementation reference

Single source of truth for Liquid Glass behavior, APIs, and patterns in this project. Grounded in the iOS 26 SDK `.swiftinterface` (cited paths below) and the empirical results of iterating the iOS player HUD.

## Quick rules

- **Liquid Glass is iOS/macOS/tvOS/watchOS 26+ only. visionOS is unavailable.** Never call this API in a `#if os(visionOS)` branch.
- **Never use `.opacity < 1` to "hide" a glass-bearing view.** It forces an offscreen render pass, hardens the material into a static bitmap, and produces a dead white/black halo at the edges. To remove glass, **remove the `.glassEffect` modifier from the hierarchy** (conditional `if`).
- **`.glassEffectTransition(.materialize)` only fires meaningfully inside a `GlassEffectContainer`.** Outside the container it degrades to plain add/remove with no shader-parameter interpolation.
- **`.regular` vs `.clear` is NOT a refraction intensity dial.** `.regular` adds an adaptive light/dark vibrancy mask on top of the same refraction layer; `.clear` skips that mask. Refraction/blur strength is fixed by the material kernel. Choose based on whether you want automatic contrast against arbitrary backdrops (`.regular`) or pure pass-through (`.clear`).
- **`.materialize` carries an inherent scale signature.** The glass visibly grows/shrinks while changing density — this is Apple's "physicalize/dematerialize" feel and there is **no public knob to suppress it**. If you don't want this scale, you don't want `.materialize`.
- **Symbols/labels riding on a glass view get sampled by `.materialize`** (and blurred during dematerialization). To keep content crisp, render it in a separate ZStack layer **above** the glass-bearing view; fade content with plain `.opacity`.

## When to use which artifact

| Need | Reach for |
|---|---|
| Full API surface (every type, signature, availability) | [references/api.md](references/api.md) |
| Proven patterns (conditional mount + materialize, separated symbol layer, container framing) | [references/patterns.md](references/patterns.md) |
| Pitfalls and corrections from real iteration (incl. `.regular` myth, symbol blur, scale signature, opacity ban) | [references/pitfalls.md](references/pitfalls.md) |

## Decision tree

1. **Need glass on a single static view?** → `.glassEffect(...)` only. No container, no transition modifier.
2. **Need glass to appear/disappear with shader parameter animation?** → `GlassEffectContainer { if cond { …glassEffect…glassEffectTransition(.materialize)… } }` + reserve outer frame.
3. **Need symbols/icons unaffected by the dematerialize blur?** → split into ZStack: glass-bearing transparent shape on bottom, symbol on top with `.opacity` fade.
4. **Multiple glass elements that should merge when close?** → wrap in `GlassEffectContainer(spacing:)`. Tune `spacing` for the desired melt threshold.
5. **Force-merge glass shapes regardless of distance?** → `.glassEffectUnion(id:namespace:)`.
6. **Match a glass instance across layout changes (like `matchedGeometryEffect`)?** → `.glassEffectID(_:in:)`.
7. **Just want a glass-styled button?** → `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)`.

## Cross-project anchors

- iOS player controls implementation: `VideoPlayer/Views/iOSPlayerControls.swift`. The center play button (`playbackButtons` HStack, middle slot) is the canonical example of the conditional-mount + container + symbol-separation pattern in this codebase.
- HIG reviewer: see the sibling skill `hig-doctor` for design-language compliance (materials chapter overlaps but does not duplicate this skill).

## SDK ground-truth path

`/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface`

Search keywords: `Glass`, `glassEffect`, `GlassEffectTransition`, `GlassEffectContainer`, `glassEffectID`, `glassEffectUnion`. Button styles live in the sibling `SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface` (search `GlassButtonStyle`, `GlassProminentButtonStyle`).
