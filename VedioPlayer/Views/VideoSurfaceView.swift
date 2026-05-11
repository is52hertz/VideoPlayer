import SwiftUI
import AVFoundation

#if os(macOS)
struct VideoSurfaceView: NSViewRepresentable {
    let engine: any PlayerEngine

    func makeNSView(context: Context) -> VideoHostView {
        let view = VideoHostView()
        engine.attachLayer(view.playerLayer)
        return view
    }

    func updateNSView(_ nsView: VideoHostView, context: Context) {}
}

final class VideoHostView: NSView {
    let playerLayer: AVPlayerLayer

    override init(frame: NSRect) {
        playerLayer = AVPlayerLayer()
        super.init(frame: frame)
        wantsLayer = true
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
#elseif os(iOS)
struct VideoSurfaceView: UIViewRepresentable {
    let engine: any PlayerEngine

    func makeUIView(context: Context) -> VideoHostView {
        let view = VideoHostView()
        engine.attachLayer(view.playerLayer)
        return view
    }

    func updateUIView(_ uiView: VideoHostView, context: Context) {}
}

final class VideoHostView: UIView {
    let playerLayer: AVPlayerLayer

    override init(frame: CGRect) {
        playerLayer = AVPlayerLayer()
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
#endif
