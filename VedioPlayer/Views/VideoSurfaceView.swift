import SwiftUI
import AVFoundation

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
