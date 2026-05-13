import SwiftUI

#if os(macOS)
import AppKit

/// Centralized layout constants for the Welcome screen.
///
/// Keep size / spacing / ratio values here so the screen can be tuned in one
/// place without hunting through views. Font *sizes* are kept here too because
/// the welcome chrome uses a few non-standard display sizes; semantic font
/// styles (`.callout`, `.headline`, `.title2`, …) continue to be used inline
/// where they fit Apple HIG defaults.
enum WelcomeLayout {
    // Window
    static let windowWidth: CGFloat = 802
    static let windowHeight: CGFloat = 470
    static let windowCornerRadius: CGFloat = 10
    static let windowBorderOpacity: Double = 0.14

    // Pane split (must sum to 1.0)
    static let leftPaneRatio: CGFloat = 0.62
    static let rightPaneRatio: CGFloat = 0.38
    static let rightPaneTintOpacity: Double = 0.08
    static let leftPaneTintOpacity: Double = 0.25

    // App icon
    static let appIconSize: CGFloat = 130
    static let appIconFrameSize: CGFloat = 120
    static let appIconBottomPadding: CGFloat = 18
    static let appIconShadowRadius: CGFloat = 10
    static let appIconShadowYOffset: CGFloat = 5
    static let appIconShadowOpacity: Double = 0.3
    static let appIconGlowSize: CGFloat = 320
    static let appIconGlowStartRadius: CGFloat = 40
    static let appIconGlowEndRadius: CGFloat = 160
    static let appIconGlowOpacity: Double = 0.15

    // Title / version block
    static let appNameFontSize: CGFloat = 28
    static let versionBottomPadding: CGFloat = 32

    // Action buttons
    static let actionButtonSpacing: CGFloat = 10
    static let actionButtonWidth: CGFloat = 350
    static let actionButtonHeight: CGFloat = 38
    static let actionButtonHorizontalPadding: CGFloat = 16
    static let actionButtonCornerRadius: CGFloat = 10
    static let actionButtonIconSpacing: CGFloat = 12
    static let actionButtonIconWidth: CGFloat = 24
    static let actionButtonHoverOpacity: Double = 0.12
    static let actionButtonRestOpacity: Double = 0.06

    // Recent video row
    static let recentRowVerticalPadding: CGFloat = 6
    static let recentRowHorizontalPadding: CGFloat = 10
    static let recentRowCornerRadius: CGFloat = 8
    static let recentRowHoverTintOpacity: Double = 0.15
    static let recentRowContentSpacing: CGFloat = 12
    static let recentRowIconFrameSize: CGFloat = 40
    static let recentRowTextSpacing: CGFloat = 2

    // Close button (Pixelmator-style)
    static let closeButtonIconSize: CGFloat = 14
    static let closeButtonPadding: CGFloat = 10
}

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
                gradient: Gradient(colors: [Color.white.opacity(WelcomeLayout.appIconGlowOpacity), Color.clear]),
                center: .center,
                startRadius: WelcomeLayout.appIconGlowStartRadius,
                endRadius: WelcomeLayout.appIconGlowEndRadius
            )
            .frame(width: WelcomeLayout.appIconGlowSize, height: WelcomeLayout.appIconGlowSize)

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
            .frame(width: WelcomeLayout.appIconSize, height: WelcomeLayout.appIconSize)
            .shadow(
                color: .black.opacity(WelcomeLayout.appIconShadowOpacity),
                radius: WelcomeLayout.appIconShadowRadius,
                y: WelcomeLayout.appIconShadowYOffset
            )
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
            .padding(.horizontal, WelcomeLayout.actionButtonHorizontalPadding)
            .frame(width: WelcomeLayout.actionButtonWidth, height: WelcomeLayout.actionButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: WelcomeLayout.actionButtonCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isHovered
                                              ? WelcomeLayout.actionButtonHoverOpacity
                                              : WelcomeLayout.actionButtonRestOpacity))
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: WelcomeLayout.actionButtonCornerRadius,
                                                     style: .continuous))
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
            .padding(.vertical, WelcomeLayout.recentRowVerticalPadding)
            .padding(.horizontal, WelcomeLayout.recentRowHorizontalPadding)
            .background(
                ZStack {
                    if isHovered {
                        RoundedRectangle(cornerRadius: WelcomeLayout.recentRowCornerRadius, style: .continuous)
                            .fill(Color.accentColor.opacity(WelcomeLayout.recentRowHoverTintOpacity))
                            .background(.thinMaterial,
                                        in: RoundedRectangle(cornerRadius: WelcomeLayout.recentRowCornerRadius,
                                                             style: .continuous))
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
