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
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
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
        guard let slider = volumeSlider else { return }
        DispatchQueue.main.async {
            if abs(slider.value - newVolume) > 0.01 {
                slider.value = newVolume
            }
        }
    }
}
#endif
