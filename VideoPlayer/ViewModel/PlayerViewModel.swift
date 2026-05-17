import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@Observable
final class PlayerViewModel {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case playing
        case paused
        case finished
        case error(String)
    }

    let engine: any PlayerEngine

    var state: State = .idle
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isControlsVisible = true
    var videoURL: URL?
    var videoTitle: String = ""
    var isShowingFilePicker = false

    var volume: Double {
        get { Double(engine.volume) }
        set { engine.volume = Float(newValue) }
    }

    #if os(iOS)
    var systemVolume: Float {
        get { SystemVolumeManager.shared.volume }
        set { SystemVolumeManager.shared.volume = newValue }
    }
    #endif

    var isHovering = false {
        didSet { handleHoverChange() }
    }

    private var autoHideTask: Task<Void, Never>?

    init(engine: any PlayerEngine = AVPlayerEngine()) {
        self.engine = engine
        setupEngineCallbacks()
    }

    // MARK: - Engine callbacks

    private func setupEngineCallbacks() {
        engine.onTimeUpdate = { [weak self] time in
            self?.currentTime = time
        }
        engine.onDurationAvailable = { [weak self] duration in
            guard let self else { return }
            self.duration = duration
            if self.state == .loading {
                self.state = .ready
            }
        }
        engine.onPlaybackEnded = { [weak self] in
            self?.state = .finished
            self?.isControlsVisible = true
        }
        engine.onError = { [weak self] error in
            self?.state = .error(error.localizedDescription)
        }
    }

    // MARK: - Public actions

    func loadVideo(url: URL) {
        let secured = url.startAccessingSecurityScopedResource()
        videoURL = url
        videoTitle = url.lastPathComponent
        state = .loading
        engine.load(url: url)

        NotificationCenter.default.post(name: .init("VideoLoadedNotification"), object: nil)

        if secured {
            // Note: In some cases you might want to defer stopAccessing until the engine is done,
            // but for simple playback loading, start/stop around the load call often suffices
            // if the engine creates its own internal security context or starts its own access.
            // However, for AVPlayer, it's safer to keep it open or let it be handled by the caller.
            // Here we follow the previous pattern but acknowledge the need for it.
            url.stopAccessingSecurityScopedResource()
        }
    }

    func closeVideo() {
        engine.reset()
        videoURL = nil
        videoTitle = ""
        currentTime = 0
        duration = 0
        state = .idle
    }

    func togglePlayPause() {
        switch state {
        case .ready, .paused, .finished:
            engine.play()
            state = .playing
        case .playing:
            engine.pause()
            state = .paused
        default:
            break
        }
    }

    func seek(to time: TimeInterval) {
        let clamped = max(0, min(time, duration))
        engine.seek(to: clamped)
        currentTime = clamped

        if state == .finished {
            state = .paused
        }
    }

    func seekForward(_ delta: TimeInterval = 10) {
        let clamped = min(currentTime + delta, duration)
        engine.seek(to: clamped)
        currentTime = clamped

        if state == .finished {
            state = .paused
        }
    }

    func seekBackward(_ delta: TimeInterval = 10) {
        let clamped = max(currentTime - delta, 0)
        engine.seek(to: clamped)
        currentTime = clamped

        if state == .finished {
            state = .paused
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                guard let self else { return }
                let resolvedURL: URL? = {
                    if let urlItem = item as? URL {
                        // Convert file-reference URLs to path URLs
                        let pathURL = (urlItem as NSURL).filePathURL ?? urlItem
                        return pathURL.standardizedFileURL.resolvingSymlinksInPath()
                    }
                    if let data = item as? Data {
                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
                            return url.standardizedFileURL.resolvingSymlinksInPath()
                        }
                        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                            if path.hasPrefix("file://") {
                                return URL(string: path)?.standardizedFileURL.resolvingSymlinksInPath()
                            } else {
                                return URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
                            }
                        }
                    }
                    return nil
                }()
                guard let resolvedURL = resolvedURL else { return }
                DispatchQueue.main.async {
                    self.loadVideo(url: resolvedURL)
                }
            }
            return true
        }

        let movieIdentifiers = videoTypes.map { $0.identifier }
        for identifier in movieIdentifiers {
            if provider.hasItemConformingToTypeIdentifier(identifier) {
                provider.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] item, _ in
                    guard let self else { return }
                    let resolvedURL: URL? = {
                        if let urlItem = item as? URL {
                            let pathURL = (urlItem as NSURL).filePathURL ?? urlItem
                            return pathURL.standardizedFileURL.resolvingSymlinksInPath()
                        }
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            return url.standardizedFileURL.resolvingSymlinksInPath()
                        }
                        return nil
                    }()
                    guard let finalURL = resolvedURL else { return }
                    DispatchQueue.main.async {
                        self.loadVideo(url: finalURL)
                    }
                }
                return true
            }
        }

        return false
    }

    func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .space:
            togglePlayPause()
            return .handled
        case .rightArrow:
            seekForward(10)
            return .handled
        case .leftArrow:
            seekBackward(10)
            return .handled
        default:
            return .ignored
        }
    }

    // MARK: - Auto-hide

    private func handleHoverChange() {
        if isHovering {
            withAnimation(.easeInOut(duration: 0.3)) {
                isControlsVisible = true
            }
            scheduleAutoHide()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isControlsVisible = false
            }
            autoHideTask?.cancel()
        }
    }

    func handleVideoTap() {
        togglePlayPause()
        withAnimation(.easeInOut(duration: 0.3)) {
            isControlsVisible.toggle()
        }

        if isControlsVisible {
            scheduleAutoHide()
        } else {
            autoHideTask?.cancel()
        }
    }

    func handleVideoTapIOS() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isControlsVisible.toggle()
        }
        if isControlsVisible {
            scheduleAutoHide()
        } else {
            autoHideTask?.cancel()
        }
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, !isHovering else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isControlsVisible = false
            }
        }
    }

    // MARK: - Supported formats

    var videoTypes: [UTType] {
        [
            .movie,
            .mpeg4Movie,
            .quickTimeMovie,
            .avi,
            .video,
            .mpeg2Video,
        ]
    }
}
