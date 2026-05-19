#if os(iOS)
import Foundation
import MediaPlayer
import AVFoundation
import Observation

@Observable
final class SystemVolumeManager {
    static let shared = SystemVolumeManager()
    
    var volume: Float = 0.5 {
        didSet {
            setSystemVolume(volume)
        }
    }
    
    private var volumeView = MPVolumeView()
    private var volumeSlider: UISlider?
    private var observer: NSKeyValueObservation?
    private static var didLogSliderLookupFailure = false

    private init() {
        setupVolumeView()
        observeSystemVolume()
    }

    private func setupVolumeView() {
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                volumeSlider = slider
                break
            }
        }
        volume = AVAudioSession.sharedInstance().outputVolume
    }

    private func observeSystemVolume() {
        // Audio session category + activation lives in AudioSessionManager.
        // We only observe outputVolume here so the UI tracks hardware-key /
        // Control Center / other-app volume changes.
        observer = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] session, change in
            guard let self = self, let newVolume = change.newValue else { return }
            Task { @MainActor in
                if abs(self.volume - newVolume) > 0.01 {
                    self.volume = newVolume
                }
            }
        }
    }

    private func setSystemVolume(_ newVolume: Float) {
        guard let slider = volumeSlider else {
            // MPVolumeView's internal UISlider has historically been the only
            // public-API path third-party code has to *write* system volume.
            // If a future iOS refactors the subview hierarchy and lookup in
            // setupVolumeView() returns nil, swallowing the write would
            // silently break the volume slider. We still update our own
            // @Observable `volume` so the UI stays consistent; the KVO on
            // outputVolume will pull truth back if anything else moves it.
            if !Self.didLogSliderLookupFailure {
                Self.didLogSliderLookupFailure = true
                print("SystemVolumeManager: MPVolumeView's inner UISlider not found; system-volume writes are inert. Read path (AVAudioSession.outputVolume + KVO) still works.")
            }
            return
        }
        Task { @MainActor in
            if abs(slider.value - newVolume) > 0.01 {
                slider.value = newVolume
            }
        }
    }
}
#endif
