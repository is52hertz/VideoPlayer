import SwiftUI

#if os(macOS)
import AppKit

/// Tracks the **system** appearance (Light vs Dark) independently of any
/// SwiftUI `colorScheme` overrides upstream. Used by `WelcomeAppIcon` so the
/// icon follows the OS setting even though `WelcomeView` itself forces a
/// `.dark` color scheme for its chrome.
@MainActor
@Observable
final class SystemAppearanceTracker {
    private(set) var isDark: Bool

    @ObservationIgnored private var observation: NSKeyValueObservation?

    init() {
        self.isDark = Self.computeIsDark()
        observation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                self?.isDark = Self.computeIsDark()
            }
        }
    }

    private static func computeIsDark() -> Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

/// A reusable background modifier for the Welcome Screen's app icon to provide a soft radial glow.
struct WelcomeAppIconGlow: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.15), Color.clear]),
                center: .center,
                startRadius: 40,
                endRadius: 160
            )
            .frame(width: 320, height: 320)
            
            content
        }
    }
}

/// A reusable view representing the App Icon for the Welcome Screen.
///
/// - Loads the high-resolution PNG from `Assets.xcassets/WelcomeAppIcon.imageset`
///   (which has Light + Dark appearance variants) rather than
///   `NSApplication.shared.applicationIconImage`, which the system downsamples
///   to standard icon sizes and yields a blurry result at 130pt on Retina.
/// - Pins the asset's color scheme to the **system** appearance, so the icon
///   keeps tracking Light/Dark mode even when `WelcomeView` forces its chrome
///   to `.dark`.
struct WelcomeAppIcon: View {
    @State private var systemAppearance = SystemAppearanceTracker()

    var body: some View {
        Image("WelcomeAppIcon")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 130, height: 130)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .accessibilityLabel(Text("VedioPlayer app icon"))
            .environment(\.colorScheme, systemAppearance.isDark ? .dark : .light)
    }
}

extension View {
    func welcomeAppIconGlow() -> some View {
        self.modifier(WelcomeAppIconGlow())
    }
}

/// A custom button style for the Welcome Screen action buttons.
struct WelcomeActionButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .frame(width: 350, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

/// A custom button style for the Recent Video row items.
struct RecentVideoRowStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                ZStack {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .environment(\.isHovered, isHovered) // Pass state to label
    }
}

// Environment key to pass hover state to the label content
private struct IsHoveredKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isHovered: Bool {
        get { self[IsHoveredKey.self] }
        set { self[IsHoveredKey.self] = newValue }
    }
}

#endif
