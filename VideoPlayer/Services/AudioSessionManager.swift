#if os(iOS)
import AVFoundation
import Observation

@MainActor
@Observable
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    /// Invoked when the system signals the player should stop audio:
    /// interruption began, or the previous output route (headphones, BT)
    /// disappeared. Owners (ViewModel) wire this to their pause path.
    var onShouldPause: (() -> Void)?
    /// Invoked when an interruption ends *and* the system flags
    /// `.shouldResume`. Not all interruptions opt into resume.
    var onShouldResume: (() -> Void)?

    private var didActivate = false

    private init() {}

    func activate() {
        guard !didActivate else { return }
        didActivate = true

        let session = AVAudioSession.sharedInstance()
        do {
            // .playback: audio plays through silent switch and continues if the
            // app loses foreground (when paired with Background Audio mode).
            // .moviePlayback mode: tuned for video, allows AirPlay routing.
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            print("AudioSessionManager: failed to configure session — \(error)")
        }

        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption(_:)),
                       name: AVAudioSession.interruptionNotification,
                       object: session)
        nc.addObserver(self,
                       selector: #selector(handleRouteChange(_:)),
                       name: AVAudioSession.routeChangeNotification,
                       object: session)
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }

        switch type {
        case .began:
            let cb = onShouldPause
            Task { @MainActor in cb?() }
        case .ended:
            guard let optRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let opts = AVAudioSession.InterruptionOptions(rawValue: optRaw)
            if opts.contains(.shouldResume) {
                let cb = onShouldResume
                Task { @MainActor in cb?() }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
        else { return }
        // Standard media-player behavior: pause when the previous output
        // disappears (headphone unplug, BT disconnect). Other reasons
        // (newDeviceAvailable, categoryChange, …) leave playback alone.
        if reason == .oldDeviceUnavailable {
            let cb = onShouldPause
            Task { @MainActor in cb?() }
        }
    }
}
#endif
