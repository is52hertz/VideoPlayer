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
/// can show true behind-window blur. Hides the title bar and traffic lights
/// completely, giving a borderless window appearance.
private struct WindowVibrancyConfigurator: NSViewRepresentable {
    let contentSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.remove(.titled)
            window.styleMask.insert(.fullSizeContentView)
            // Hide traffic light buttons (in case they persist)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            // Lock size
            window.contentMinSize = contentSize
            window.contentMaxSize = contentSize
            window.setContentSize(contentSize)
            window.center()
            // Allow dragging from anywhere
            window.isMovableByWindowBackground = true
            // Round the window's content view at the AppKit level
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 10
            window.contentView?.layer?.masksToBounds = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Configures the window for transparency and pins its content size.
    /// Call once on the root view of a single-window scene.
    func windowVibrancy(contentSize: NSSize) -> some View {
        self.background(WindowVibrancyConfigurator(contentSize: contentSize))
    }
}
#endif
