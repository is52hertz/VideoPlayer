#if os(macOS)
import SwiftUI
import AppKit

/// NSVisualEffectView wrapper — use different `material` values to control
/// the tint/darkness without losing blur quality.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

/// Configures the hosting NSWindow for transparency so NSVisualEffectView
/// can show true behind-window blur.
private struct WindowVibrancyConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Configures the window for transparency (call once on the root view).
    func windowVibrancy() -> some View {
        self.background(WindowVibrancyConfigurator())
    }
}
#endif
