import SwiftUI

#if os(macOS)

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

/// A reusable view representing the stylized App Icon for the Welcome Screen.
struct WelcomeAppIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.3, blue: 0.5), Color(red: 0.1, green: 0.15, blue: 0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 128, height: 128)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .overlay {
                Image(systemName: "play.square.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
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
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                            .fill(Color.accentColor.opacity(0.2))
                            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
