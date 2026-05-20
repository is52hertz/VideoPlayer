# Liquid Glass — pitfalls and corrections

Every entry here is something that wasted real time during iteration. Read before you reach for the obvious-looking solution.

## 1. `.regular` is not a "thicker refraction" knob

**Wrong mental model**: "`.clear` is thin glass, `.regular` is thick glass with stronger refraction."

**Reality**: `.regular` and `.clear` share the **same** refraction/blur kernel. The difference is that `.regular` adds an adaptive vibrancy mask layer — the system samples the underlying backdrop brightness and overlays a tinted light/dark shade so foreground content stays legible. `.clear` skips that mask.

So switching `.clear` → `.regular` won't make the materialize transition "more dramatic" — it'll just add a vibrancy shade. If you actually want a more visible material, options are:

- Add a tint: `.clear.tint(.white.opacity(0.15))`
- Place glass over a higher-contrast/brighter backdrop so its existing refraction reads more strongly.
- Accept the trade-off and use `.regular` only when you actually need legibility insurance, not for "thickness."

## 2. `.opacity < 1` on glass-bearing views is forbidden

Setting `.opacity(0..<1)` on a view that carries `.glassEffect` causes the system to flatten the glass into an offscreen bitmap before alpha-blending. Result:
- Performance drop (offscreen render pass).
- A "dead white" / "dead black" halo around the edges where the material's normal compositing path is bypassed.
- The shader-parameter animation stops participating — you get a static frozen image fading out.

**Correct way to hide glass**: conditionally remove the `.glassEffect` modifier itself via `if condition { … .glassEffect(...) … }`. Pair with `.glassEffectTransition(.materialize)` for a smooth dematerialization.

`.opacity` is still fine on **non-glass** layers (icons, labels) layered above the glass — see pitfall #4.

## 3. `.materialize` only animates inside a `GlassEffectContainer`

Standalone:
```swift
view
    .glassEffect(.clear, in: Circle())
    .glassEffectTransition(.materialize)
```
This *looks* like it should work, but without a container ancestor it degrades to plain add/remove — the glass just blinks in/out (or whatever the parent's `.transition()` says).

The container owns the backdrop sampling and shader pipeline that does the actual parameter interpolation. **Always wrap a materializing glass in a `GlassEffectContainer`**, even if there's only one glass child:

```swift
GlassEffectContainer {
    if isVisible {
        view
            .glassEffect(.clear, in: Circle())
            .glassEffectTransition(.materialize)
            .glassEffectID("x", in: ns)
    }
}
```

## 4. Symbols/labels inside a glass view get blurred during materialize

`.glassEffect` makes the view it's attached to (including its content subtree) a single glass instance. When `.materialize` runs, the *entire instance* — backdrop sample + content — goes through the shader's dematerialization, so foreground symbols/labels blur and fade together with the material.

This is rarely what you want for icons.

**Fix**: split into two ZStack layers. Bottom = transparent glass-bearing shape (the only thing that gets materialize). Top = symbol/text, separate from the glass chain, fades via plain `.opacity`. See `patterns.md` Pattern B for the canonical form.

## 5. `.materialize` includes an inherent scale animation

Users who expect "just refraction/blur dissipating" sometimes notice the glass also visibly *grows/shrinks* during the transition. That's not a bug — it's the "physicalize/dematerialize" signature Apple bakes into this transition, modeling the material gaining/losing volume.

There is **no public API to disable the scale component while keeping the parameter animation**. The choices are:
- Accept it (it's the Apple TV / system-HUD feel).
- Use `.identity` or `.matchedGeometry` instead (loses parameter animation).

Don't burn time trying to counter-scale or wrap with `.scaleEffect` — you'll fight the transition and lose.

## 6. `glassEffect` does not take `isEnabled`

Several third-party blog posts and AI-generated docs claim `.glassEffect(_, in:, isEnabled:)` exists. **It does not.** The real signature from the SDK swiftinterface is:

```swift
public func glassEffect(
    _ glass: Glass = .regular,
    in shape: some Shape = DefaultGlassEffectShape()
) -> some View
```

To toggle, use conditional mount (`if` inside a `@ViewBuilder`), not a parameter.

## 7. Conditional `if` inside `@ViewBuilder` is OK — but the alternatives have gotchas

When you write:
```swift
if active {
    content.glassEffect(...).glassEffectTransition(.materialize)
} else {
    content
}
```
SwiftUI sees this as a `_ConditionalContent` with two branches and may treat them as different identities. For Pattern B (Pattern B from `patterns.md`) we keep the glass-bearing view inside a single-branch `if` block (no `else`), which means it's truly added/removed — that's what fires `.materialize`.

If you must use `if/else` (because the false branch still needs to draw something), apply `.glassEffectID(_:in:)` so SwiftUI matches identity across the branches.

## 8. visionOS

The entire Liquid Glass API surface is `@available(visionOS, unavailable)`. Don't put glass code behind a `#if os(visionOS)` block hoping it'll compile — it won't. visionOS has its own material model and you should branch the design, not the implementation.

## 9. `.contentTransition` competes with materialize

Stacking `.contentTransition(.symbolEffect(.replace))` on a symbol *inside* the same glass-effect view chain can produce stuttery double-animations during materialize, because the symbol is being asked to do both a content swap and ride the glass dematerialization.

**Fix**: keep `.contentTransition` on the symbol layer in the ZStack (above glass), where it only governs symbol replacement and is unaffected by glass transitions.

## 10. Avoid `.scaleEffect(0.6)` "shrink into nothing"

Old habit from pre-iOS-26: shrink + fade buttons to dismiss. Looks fine on flat material but on glass it reads as "the button got sucked through a pinhole" because the material is supposed to have physical weight. Apple TV's HUD release is a slight outward scale + dematerialize — *if* you want a scale at all, scale **up** (~1.04–1.08), not down. Or skip the scale entirely and let `.materialize`'s own signature carry the motion.
