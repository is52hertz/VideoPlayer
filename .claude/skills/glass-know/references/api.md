# Liquid Glass — full public API surface (iOS 26 SDK)

All declarations below verified against `SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface` (and `SwiftUI.swiftmodule` for button styles). All are `@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *)` and `@available(visionOS, unavailable)`.

## `Glass` — the material descriptor

```swift
public struct Glass: Equatable, Sendable {
    public static var regular: Glass    // adaptive light/dark vibrancy mask + base refraction
    public static var clear:   Glass    // base refraction only, no vibrancy mask
    public static var identity: Glass   // no material; useful as an animation/disabled endpoint

    public func tint(_ color: Color?) -> Glass         // colorize the material
    public func interactive(_ isEnabled: Bool = true) -> Glass  // touch highlight reaction
}
```

Composable: `.regular.tint(.blue).interactive()`.

**Important**: `.regular` and `.clear` share the same refraction/blur kernel; the difference is whether a vibrancy mask is layered on top.

## Attaching glass to a view

```swift
extension View {
    public func glassEffect(
        _ glass: Glass = .regular,
        in shape: some Shape = DefaultGlassEffectShape()
    ) -> some View
}
```

- `DefaultGlassEffectShape` is a system-chosen capsule.
- Any `Shape` is accepted: `Circle()`, `RoundedRectangle(cornerRadius: 24, style: .continuous)`, `Capsule()`, `Ellipse()`, `ContainerRelativeShape()`, custom `Path`.
- **No `isEnabled` parameter exists.** Toggle by conditionally applying the modifier (wrap with `if`).

## Add/remove transitions

```swift
public struct GlassEffectTransition: Sendable {
    public static var matchedGeometry: GlassEffectTransition   // default — morph between matched geometries
    public static var materialize:     GlassEffectTransition   // physicalize/dematerialize via shader-param + scale
    public static var identity:        GlassEffectTransition   // no transition
}

extension View {
    public func glassEffectTransition(_ transition: GlassEffectTransition) -> some View
}
```

- `.materialize` is what gives the "refraction/blur dissipating" feel users associate with Apple TV HUDs. It also includes an inherent scale animation; this is not configurable.
- Transitions fire when the `.glassEffect` modifier itself is added/removed (driven by conditional mount), and require a `GlassEffectContainer` ancestor to engage the backdrop shader pipeline.

## Container (groups, morphing, shader pipeline)

```swift
public struct GlassEffectContainer<Content: View>: View {
    public init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}
```

- `spacing`: distance threshold below which child glass shapes melt into one (liquid fusion). `nil` = system default.
- Owns the backdrop sampling/shading pipeline that interpolates blur radius / refraction weights when children are added or removed. Without a container, `.glassEffectTransition` falls back to a plain add/remove with no parameter animation.
- Children inside the container with overlapping shapes blend; outside, each glass renders independently.

## Identity & forced union

```swift
extension View {
    public func glassEffectID(
        _ id: (some Hashable & Sendable)?,
        in namespace: Namespace.ID
    ) -> some View

    public func glassEffectUnion(
        id: (some Hashable & Sendable)?,
        namespace: Namespace.ID
    ) -> some View
}
```

- `glassEffectID`: same role as `matchedGeometryEffect` but for glass material instances — lets SwiftUI carry shader-parameter state across state changes.
- `glassEffectUnion`: explicitly merges multiple glass shapes into one logical material region regardless of spacing distance.

## Button styles

In `SwiftUI` (main module):

```swift
extension PrimitiveButtonStyle where Self == GlassButtonStyle {
    public static var glass: GlassButtonStyle { get }
    public static func glass(_ glass: Glass) -> Self
}

extension PrimitiveButtonStyle where Self == GlassProminentButtonStyle {
    public static var glassProminent: GlassProminentButtonStyle { get }
}
```

Usage:
```swift
Button("Tap") { }.buttonStyle(.glass)
Button("Tap") { }.buttonStyle(.glass(.clear.interactive()))
Button("Tap") { }.buttonStyle(.glassProminent)
```

## Animation driver options

`.glassEffectTransition(.materialize)` only declares *what* the transition is; the *when* and *how-fast* come from one of:

- Implicit: `.animation(_:value:)` on an ancestor — fires whenever the bound value changes.
- Explicit: `withAnimation(_) { state.toggle() }` around the mutation site.
- Default: with no animation, transitions snap to the next frame (rarely desirable for glass).

Content inside the glass-bearing view can use orthogonal animations:
- `.contentTransition(.symbolEffect(.replace))` for SF Symbol swaps.
- `.symbolEffect(.bounce / .pulse / .rotate)` for symbol effects.
- `.scaleEffect`, `.offset`, `.rotationEffect` for layout-time animation.

## Visual property summary

| Property | API surface |
|---|---|
| Material variant | `Glass.regular / .clear / .identity` |
| Tint color | `Glass.tint(.color?)` |
| Touch reactivity | `Glass.interactive(_ isEnabled: Bool = true)` |
| Shape | `glassEffect(_, in: someShape)` |
| Neighbor fusion distance | `GlassEffectContainer(spacing:)` |
| Forced fusion | `.glassEffectUnion(id:namespace:)` |
| Cross-state identity | `.glassEffectID(_:in:)` |
| Add/remove animation | `.glassEffectTransition(.materialize / .matchedGeometry / .identity)` |
| Animation timing | ancestor `.animation(_, value:)` or `withAnimation { … }` |
| Embedded symbol transitions | `.contentTransition(.symbolEffect(...))` |

## SDK source paths

- Core: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface`
- Button styles: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface`

## Apple Developer references

- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [GlassEffectTransition](https://developer.apple.com/documentation/swiftui/glasseffecttransition)
- [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))
- [glassEffectID(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:))
- [glassEffectUnion(id:namespace:)](https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:))
