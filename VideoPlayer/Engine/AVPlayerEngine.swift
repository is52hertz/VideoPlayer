import AVFoundation

final class AVPlayerEngine: NSObject, PlayerEngine {
    private let player = AVPlayer()
    private var timeObserverToken: Any?
    private var item: AVPlayerItem?
    private var durationObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var chaseTime: CMTime = .invalid
    private var isSeekInProgress = false

    var currentTime: TimeInterval {
        guard player.currentItem != nil else { return 0 }
        let time = player.currentTime()
        return time.isNumeric ? time.seconds : 0
    }

    var duration: TimeInterval? {
        guard let item = player.currentItem, item.duration.isNumeric else { return nil }
        return item.duration.seconds
    }

    var isPlaying: Bool { player.rate != 0 }

    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }

    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onDurationAvailable: ((TimeInterval) -> Void)?
    var onPlaybackEnded: (() -> Void)?
    var onError: ((Error) -> Void)?

    override init() {
        super.init()
        // QA1820 trade-off: disables AVPlayer's buffer-pause heuristic to keep
        // scrub seeks low-latency. Safe for local files; re-enable (set true)
        // if/when this engine is used for network/HLS streams.
        player.automaticallyWaitsToMinimizeStalling = false
        setupTimeObserver()
    }

    deinit {
        teardown()
    }

    func load(url: URL) {
        teardownItemObservers()
        let newItem = AVPlayerItem(url: url)
        // QA1820 trade-off: tiny forward buffer keeps post-seek latency low.
        // Fine for local files; raise (e.g. 5–10) for network playback where
        // bandwidth dips need headroom.
        newItem.preferredForwardBufferDuration = 1
        item = newItem
        player.replaceCurrentItem(with: newItem)
        observeItem(newItem)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekScrubbing(to time: TimeInterval) {
        chaseTime = CMTime(seconds: time, preferredTimescale: 600)
        if !isSeekInProgress { trySeekToChaseTime() }
    }

    private func trySeekToChaseTime() {
        guard !isSeekInProgress, chaseTime.isValid, player.currentItem != nil else { return }
        let target = chaseTime
        isSeekInProgress = true
        // QA1820 trade-off: infinite tolerance snaps to the nearest already-
        // decoded sync sample (I-frame), so during a drag only I-frames
        // appear — mid-GOP frames are skipped. Acceptable because the View
        // calls `seek(to:)` (zero tolerance) on release to land the exact
        // frame. Do NOT lower tolerance here without also accepting the
        // multi-frame latency that returns.
        player.seek(
            to: target,
            toleranceBefore: .positiveInfinity,
            toleranceAfter: .positiveInfinity
        ) { [weak self] _ in
            guard let self else { return }
            self.isSeekInProgress = false
            if CMTimeCompare(self.chaseTime, target) != 0 {
                self.trySeekToChaseTime()
            }
        }
    }

    func seekForward(_ delta: TimeInterval) {
        seek(to: currentTime + delta)
    }

    func seekBackward(_ delta: TimeInterval) {
        seek(to: max(0, currentTime - delta))
    }

    func attachLayer(_ layer: AVPlayerLayer) {
        layer.player = player
    }

    func reset() {
        pause()
        teardownItemObservers()
        player.replaceCurrentItem(with: nil)
        item = nil
    }

    // MARK: - Time observation

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.onTimeUpdate?(self.currentTime)
        }
    }

    // MARK: - Item observation

    private func observeItem(_ item: AVPlayerItem) {
        durationObserver = item.observe(\.duration, options: [.new]) { [weak self] item, _ in
            guard let self, item.duration.isNumeric else { return }
            self.onDurationAvailable?(item.duration.seconds)
        }

        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .failed, let error = item.error {
                self.onError?(error)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.onPlaybackEnded?()
        }
    }

    private func teardownItemObservers() {
        durationObserver?.invalidate()
        durationObserver = nil
        statusObserver?.invalidate()
        statusObserver = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func teardown() {
        teardownItemObservers()
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
}
