import AVFoundation

protocol PlayerEngine: AnyObject {
    var currentTime: TimeInterval { get }
    var duration: TimeInterval? { get }
    var isPlaying: Bool { get }
    var volume: Float { get set }

    var onTimeUpdate: ((TimeInterval) -> Void)? { get set }
    var onDurationAvailable: ((TimeInterval) -> Void)? { get set }
    var onPlaybackEnded: (() -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func load(url: URL)
    func play()
    func pause()
    func seek(to time: TimeInterval)
    /// Coalesced, lossy seek for live scrubbing. Multiple rapid calls only
    /// ever have one in flight; tolerance is wide for low latency. Follow
    /// with `seek(to:)` on release to commit the exact frame.
    func seekScrubbing(to time: TimeInterval)
    func seekForward(_ delta: TimeInterval)
    func seekBackward(_ delta: TimeInterval)
    func attachLayer(_ layer: AVPlayerLayer)
    func reset()
}
