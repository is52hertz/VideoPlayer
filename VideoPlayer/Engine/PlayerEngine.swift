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
    func seekForward(_ delta: TimeInterval)
    func seekBackward(_ delta: TimeInterval)
    func attachLayer(_ layer: AVPlayerLayer)
    func reset()
}
