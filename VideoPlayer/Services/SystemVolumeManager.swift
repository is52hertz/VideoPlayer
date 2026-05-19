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

    /// ⚠️ 文档外承诺警告 (long-term risk):
    /// 这个 MPVolumeView 实例**不在任何 window 视图层级里**，仅作为读写系统
    /// 音量的桥。我们依赖它的 inner UISlider.value 与系统音量实时双向绑定
    /// 这一行为 —— **Apple 没明确文档承诺** detached MPVolumeView 也会同步。
    /// 实测在 iOS 26 上 OK，但未来大版本可能破。若破，syncFromSystem 会回
    /// 落到 AVAudioSession.outputVolume（受 stale 问题影响，质量降级但不
    /// 致命，由 resyncWithRetries 的延迟重读兜底）。
    /// 备选方案：让本类不自建 MPVolumeView，改为接收 VolumeViewWrapper
    /// （iOSPlayerControls 里那个 in-hierarchy 的 offscreen MPVolumeView）
    /// 的 slider 引用 —— 待观察到回归再做。
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

    /// 主动从系统读取一次真实音量。
    /// 触发场景：松手（isUserInteracting false 跳变）、回前台、scenePhase = .active。
    ///
    /// 真值源优先级：
    ///   1. MPVolumeView 内部 slider.value —— 实时双向绑定到系统音量，
    ///      在 app 后台时若用户外部改音量它也会跟着变；didBecomeActive
    ///      时立即就是新值，不像 AVAudioSession.outputVolume 那样有
    ///      会话激活后短暂返回 stale 的窗口期。
    ///   2. AVAudioSession.outputVolume —— fallback。**质量降级**：本身
    ///      就是上一次 bug 的根因（stale），但 resyncWithRetries 在
    ///      0/100/300/600/1200ms 五次重读，600~1200ms 时通常已 fresh，
    ///      属于护城河。仅在主路径（slider）失效时才会走到。
    func syncFromSystem() {
        // 拖动期间手指 = 唯一真理。和 KVO handler 同款短路。
        // 极端场景：用户刚回前台 1.2s 窗口内立刻拖动音量条，resyncWithRetries
        // 的后续延迟读会和手指打架，本守门阻断之。
        guard !isUserInteracting else { return }

        let truth: Float = volumeSlider?.value ?? AVAudioSession.sharedInstance().outputVolume
        if abs(volume - truth) > 0.005 {
            volume = truth
        }
    }

    /// 后台 → 前台 / scenePhase 变化触发的高鲁棒性同步。
    /// 现在 + 100 + 300 + 600 + 1200ms 共 5 次重读，覆盖系统刷新延迟。
    /// 后面几次大概率读到的是同一个稳定值，多调几次代价可忽略。
    func resyncWithRetries() {
        Task { @MainActor in
            let delays: [Int] = [0, 100, 300, 600, 1200]
            for delay in delays {
                if delay > 0 {
                    try? await Task.sleep(for: .milliseconds(delay))
                }
                syncFromSystem()
            }
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
        // 双路径冗余（intentional belt-and-suspenders）：
        //   - 本 NotificationCenter 观察器（didBecomeActive）
        //   - VideoPlayerApp 里 scenePhase = .active onChange 触发的
        //     SystemVolumeManager.shared.resyncWithRetries()
        // 一次切回前台会**同时**触发两路，各跑 5 次延迟重读 ≈ 1.2s 内 10
        // 次 read。看上去冗余，**不要随便砍**：早期版本只走单路（先是
        // willEnterForeground，后是 didBecomeActive 单 sync）都被实测发现
        // 漏过外部音量变化。两条路径源自完全不同的 iOS 子系统
        // （UIKit Notification vs SwiftUI scene lifecycle），冗余可以
        // hedge 任一子系统的投递异常。read 是幂等的，无副作用 —— 留着。
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resyncWithRetries()
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
