#if os(macOS)
import SwiftUI
import AppKit

struct WindowTrackerView: NSViewRepresentable {
    @Binding var isVisible: Bool
    var onHover: (Bool) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.setupTrackingArea(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateTitleBar(for: nsView.window, isVisible: isVisible)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSResponder {
        var parent: WindowTrackerView
        var trackingArea: NSTrackingArea?

        init(_ parent: WindowTrackerView) {
            self.parent = parent
            super.init()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupTrackingArea(for view: NSView) {
            if let trackingArea = trackingArea {
                view.removeTrackingArea(trackingArea)
            }
            
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeAlways,
                .inVisibleRect
            ]
            
            trackingArea = NSTrackingArea(rect: view.bounds, options: options, owner: self, userInfo: nil)
            view.addTrackingArea(trackingArea!)
        }

        override func mouseEntered(with event: NSEvent) {
            parent.onHover(true)
        }

        override func mouseMoved(with event: NSEvent) {
            parent.onHover(true)
        }

        override func mouseExited(with event: NSEvent) {
            parent.onHover(false)
        }

        func updateTitleBar(for window: NSWindow?, isVisible: Bool) {
            guard let window = window else { return }
            
            // Re-enable window resizing (in case it was disabled by Welcome Screen)
            if !window.styleMask.contains(.resizable) {
                window.styleMask.insert(.resizable)
            }
            
            // Ensure full size content view so content is under the title bar
            if !window.styleMask.contains(.fullSizeContentView) {
                window.styleMask.insert(.fullSizeContentView)
            }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = isVisible ? .visible : .hidden
            
            // Fade out traffic lights (close/miniaturize/zoom buttons)
            if let titlebarContainer = window.standardWindowButton(.closeButton)?.superview {
                titlebarContainer.animator().alphaValue = isVisible ? 1.0 : 0.0
            }
        }
    }
}
#endif
