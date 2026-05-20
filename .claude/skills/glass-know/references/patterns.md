# Liquid Glass — implementation patterns

Hands-on patterns verified by iterating the iOS player HUD in this project.

## Pattern A — Static glass surface

When the view never appears/disappears and you just want material on it (e.g. a permanent pill background).

```swift
HStack(spacing: 12) {
    Image(systemName: "speaker.wave.3.fill")
    Text("Audio")
}
.padding(.horizontal, 16)
.padding(.vertical, 10)
.glassEffect(.clear.interactive(), in: Capsule())
```

No container, no transition, no namespace. Don't over-engineer.

## Pattern B — Materialize on add/remove (canonical)

For a glass element that should *physically materialize* into and out of existence, with proper backdrop-shader parameter animation.

```swift
@Namespace private var glassNamespace

ZStack {
    // Glass backdrop layer (conditional; carries the transition)
    GlassEffectContainer(spacing: 20) {
        if isVisible {
            Circle()
                .fill(Color.clear)            // transparent — material is the visual
                .frame(width: 88, height: 88)
                .glassEffect(.clear.interactive(), in: Circle())
                .glassEffectTransition(.materialize)
                .glassEffectID("myButton", in: glassNamespace)
        }
    }
    .frame(width: 88, height: 88)             // reserve slot for parent layout

    // Symbol layer (always present; orthogonal opacity fade — see pitfalls.md)
    Image(systemName: "play.fill")
        .font(.system(size: 36, weight: .semibold))
        .foregroundStyle(.white)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(false)
}
.frame(width: 88, height: 88)
.contentShape(Circle())
.onTapGesture {
    guard isVisible else { return }
    action()
}
```

Animation timing comes from an ancestor:
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.75), value: isVisible)
```

Why each piece is necessary:

| Piece | Why |
|---|---|
| `GlassEffectContainer` | Owns the backdrop shader pipeline that interpolates blur radius / refraction weights. Without it, `.materialize` falls back to a plain add/remove. |
| `if isVisible { … }` | `.glassEffect` is detached from the modifier chain when the condition flips — that *is* the trigger for `.materialize`. |
| `Circle().fill(.clear)` | A neutral host for the material. We don't put real content here because anything inside the glass-bearing view rides the shader (gets blurred during dematerialization). |
| `.glassEffectTransition(.materialize)` | Declares this is a materialize add/remove, not a matched-geometry morph. |
| `.glassEffectID("…", in:)` | Lets SwiftUI maintain shader-parameter state for this glass instance across state changes. Required for clean interpolation. |
| Outer `.frame` on both container and ZStack | Reserves layout slot so the parent stack doesn't collapse during the dematerialized phase. |
| Separate `Image` layer above the glass in the ZStack | Keeps the symbol *outside* the glass-effect view chain, so it's not sampled into the backdrop and the materialize blur never touches it. |
| `Image.opacity(...)` driven by the same `isVisible` | Symbol fades cleanly while glass dematerializes — two independent visuals that share timing via the ancestor `.animation(...)`. |

## Pattern C — Multi-glass fusion (toolbar)

For a strip of glass pills that should melt together when within `spacing`pt of each other.

```swift
GlassEffectContainer(spacing: 12) {
    HStack(spacing: 8) {
        ForEach(items) { item in
            ItemView(item)
                .glassEffect(.regular.interactive(), in: Capsule())
        }
    }
}
```

- Drop `spacing` below the inter-item gap to keep them separate.
- Force a permanent union regardless of distance: `.glassEffectUnion(id:namespace:)`.

## Pattern D — Glass button styles (lightest touch)

For simple buttons that need a system-styled glass surface — let Apple drive the entire material.

```swift
Button("Continue") { /* ... */ }
    .buttonStyle(.glass)

Button("Confirm") { /* ... */ }
    .buttonStyle(.glassProminent)
```

Use these when you have no need to control material shape, container, or transition — they're a shortcut for the most common case.

## Pattern E — Symbol-only content inside a permanent glass shape

When you do want the symbol to ride the glass shape (e.g. it's part of the same logical surface) but still want it visible during all states:

```swift
Image(systemName: "xmark")
    .font(.system(size: 16, weight: .semibold))
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .glassEffect(.clear.interactive(), in: Capsule())
```

This is fine because the glass never disappears — no materialize, no blur on the symbol.

## When patterns clash

- **Don't combine Pattern B's `if`-mount with Pattern E's symbol-inside-glass.** The symbol will ride the materialize blur. Switch to Pattern B and separate the layers.
- **Don't put two unrelated glasses in one container if you don't want them to fuse.** Either raise `spacing` so they can't touch, or split into two containers.
- **Don't sprinkle `.glassEffectTransition` outside a container.** It's a no-op.

## In-repo canonical example

The center play button in `VideoPlayer/Views/iOSPlayerControls.swift` (inside `playbackButtons`) is a literal implementation of Pattern B. Read it when in doubt.
