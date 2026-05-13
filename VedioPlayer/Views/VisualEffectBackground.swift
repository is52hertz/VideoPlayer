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
/// can show true behind-window blur. Also enables `fullSizeContentView` and
/// pins the window to a fixed content size so SwiftUI layout and the
/// overlay border align with the actual NSWindow bounds.
private struct WindowVibrancyConfigurator: NSViewRepresentable {
    let contentSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            // Lock the window to the requested content size. Using min/max
            // content size avoids fights with SwiftUI's contentSize
            // resizability and any restored window state.
            window.contentMinSize = contentSize
            window.contentMaxSize = contentSize
            window.setContentSize(contentSize)
            window.center()
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
