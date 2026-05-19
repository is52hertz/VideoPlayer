#if os(iOS)
import Foundation
import UIKit
import MediaPlayer
import AVFoundation
import Observation

@Observable
final class SystemVolumeManager {
    static let shared = SystemVolumeManager()

    /// 只读对外。改动只能走 setUserVolume(_:)、KVO 内部路径、或 syncFromSystem。
    /// 拒绝外部直接 = 赋值是设计性的：避免反馈环（KVO 写 volume → didSet 写
    /// slider → AVAudioSession 内部更新 → KVO 又触发 → ...），并强制 UI 拖动
    /// 走 setUserVolume 入口，让"是否屏蔽 KVO 回写"的策略集中在这一处。
    private(set) var volume: Float = 0.5

    /// View 在 drag 期间应置 true。期间 KVO 不回写 volume，避免和手指打架
    /// （write slider 异步、KVO 即时，前后值会"前进 → 回退"抽搐）。
    /// 由 true → false 时自动 syncFromSystem，吸收松手后系统真实落点。
    var isUserInteracting: Bool = false {
        didSet {
            guard oldValue && !isUserInteracting else { return }
            syncFromSystem()
        }
    }

    private var volumeView = MPVolumeView()
    private var volumeSlider: UISlider?
    private var kvoObserver: NSKeyValueObservation?
    private var foregroundObserver: NSObjectProtocol?
    private static var didLogSliderLookupFailure = false

    private init() {
        setupVolumeView()
        observeSystemVolume()
        observeForeground()
    }

    // MARK: - Public API

    /// UI 拖动写入入口。本地 volume 立刻反映手指位置，再异步写 slider。
    /// 拖动期间 KVO 短路；松手时 syncFromSystem 吸收延迟。
    func setUserVolume(_ newValue: Float) {
        let clamped = max(0, min(1, newValue))
        volume = clamped
        writeToSystem(clamped)
    }

    /// 主动从 AVAudioSession 读取一次系统真实音量。
    /// 触发场景：松手（isUserInteracting false 跳变）、回前台。
    func syncFromSystem() {
        let truth = AVAudioSession.sharedInstance().outputVolume
        if abs(volume - truth) > 0.005 {
            volume = truth
        }
    }

    // MARK: - Setup

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
        kvoObserver = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, let newVolume = change.newValue else { return }
            Task { @MainActor in
                // 拖动期间手指 = 唯一真理。松手由 isUserInteracting.didSet 统一吸收。
                guard !self.isUserInteracting else { return }
                if abs(self.volume - newVolume) > 0.005 {
                    self.volume = newVolume
                }
            }
        }
    }

    private func observeForeground() {
        // App 在后台时 KVO 投递不可靠（系统合并 / 暂停）。回前台主动重读。
        // 用 didBecomeActive 而非 willEnterForeground：后者在 scene-based app
        // 上不一定触发，且 AVAudioSession.outputVolume 在 willEnterForeground
        // 时常仍是 stale 值。didBecomeActive 时 session 已 reactivate。
        // 再保险：300ms 后追读一次，吸收 session 刚激活时 outputVolume 仍未
        // 刷新的短暂窗口（实测有几十~几百毫秒的滞后）。
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncFromSystem()
                try? await Task.sleep(for: .milliseconds(300))
                self?.syncFromSystem()
            }
        }
    }

    private func writeToSystem(_ value: Float) {
        guard let slider = volumeSlider else {
            // MPVolumeView 内部 UISlider 查找失败 fallback：仍保留本地 volume
            // （UI 已经反映手指），但 write 不达；KVO 也无法回流写值。
            // 仅首次报警，避免日志爆炸。
            if !Self.didLogSliderLookupFailure {
                Self.didLogSliderLookupFailure = true
                print("SystemVolumeManager: MPVolumeView's inner UISlider not found; system-volume writes are inert. Read path (AVAudioSession.outputVolume + KVO) still works.")
            }
            return
        }
        Task { @MainActor in
            if abs(slider.value - value) > 0.005 {
                slider.value = value
            }
        }
    }
}
#endif
