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

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = videoTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadVideo(url: url)
    }

    func loadVideo(url: URL) {
        videoURL = url
        videoTitle = url.lastPathComponent
        state = .loading
        engine.load(url: url)
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
            isControlsVisible = true
            autoHideTask?.cancel()
        } else {
            scheduleAutoHide()
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

    private var videoTypes: [UTType] {
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
