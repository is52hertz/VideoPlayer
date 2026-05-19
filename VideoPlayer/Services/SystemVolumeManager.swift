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

    // MARK: - Haptic state
    //
    // 自绘音量 UI 把系统 volume HUD 抑制掉后，原生硬件键 haptic 也一并丢了
    // （Apple 把这两件事捆绑在同一条系统路径里，没有公开 API 单独保留 haptic）。
    // 我们用 KVO 上观察到的音量变化模式来复刻原生反馈：
    //   - 单按一次：自然静默（lastKVOTime 距 now > 200ms，非连续节奏）
    //   - 长按连续：每越过 1/16 一格震一次
    //   - 到顶 / 到底：震一次（即使单按按到也震）
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    private var lastHapticVolume: Float = 0
    private var lastHapticTime: Date = .distantPast
    private var lastKVOTime: Date = .distantPast
    private static let nativeStep: Float = 1.0 / 16.0
    private static let continuousWindow: TimeInterval = 0.2
    private static let hapticMinInterval: TimeInterval = 0.05
    private static let boundaryEpsilon: Float = 0.001

    private init() {
        setupVolumeView()
        observeSystemVolume()
        observeForeground()
        // 预热 haptic 引擎，降低首触延迟。
        hapticGenerator.prepare()
        // 起点对齐当前真值，第一次 KVO 才能按 delta 正确算"越过 1/16"。
        lastHapticVolume = volume
    }

    // MARK: - Public API

    /// UI 拖动写入入口。本地 volume 立刻反映手指位置，再异步写 slider。
    /// 拖动期间 KVO 短路；松手时 syncFromSystem 吸收延迟。
    /// Haptic：手指首次穿越到顶 / 到底时震一次。**不**复刻原生硬件键
    /// "已到顶持续提醒"行为 —— 那是 hardware key 独有的 HIG 反馈，
    /// 手指拖到顶后保持不动不该继续震（会让 UI 反馈"卡住"感）。
    func setUserVolume(_ newValue: Float) {
        let clamped = max(0, min(1, newValue))
        let oldVolume = volume
        volume = clamped
        writeToSystem(clamped)
        if crossedBoundary(oldVolume: oldVolume, newVolume: clamped) {
            fireHapticThrottled()
        }
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
                    let oldVolume = self.volume
                    self.volume = newVolume
                    self.evaluateHaptic(oldVolume: oldVolume, newVolume: newVolume)
                }
            }
        }
    }

    /// 根据原生硬件键节奏决定是否 fire haptic。规则见类注释 (Haptic state)。
    /// 仅 KVO 路径调；UI 拖动走 setUserVolume，由它自己处理 boundary haptic。
    private func evaluateHaptic(oldVolume: Float, newVolume: Float) {
        let now = Date()
        defer { lastKVOTime = now }

        // "长按中" = 当前 KVO 距上次 KVO < 200ms。首次 KVO 不算长按（单按静默）。
        let isContinuous = lastKVOTime != .distantPast
            && now.timeIntervalSince(lastKVOTime) < Self.continuousWindow
        // 越过原生一格步进 (1/16)，留 0.005 epsilon 容忍浮点抖动。
        let crossedStep = abs(newVolume - lastHapticVolume) >= Self.nativeStep - 0.005
        let isBoundary = crossedBoundary(oldVolume: oldVolume, newVolume: newVolume)

        let shouldHaptic = isBoundary || (isContinuous && crossedStep)
        guard shouldHaptic else { return }

        if fireHapticThrottled() {
            lastHapticVolume = newVolume
        }
    }

    /// 首次穿越 0 / 1 判定。两条路径用：
    ///   - setUserVolume（UI 拖动）：手指拖到边界震一次；拖回再拖到边界
    ///     再震 —— 这就是用户期望的"凡触达即反馈"。
    ///   - evaluateHaptic（KVO 路径，硬件键 / CC / 其他 app）：外部音量
    ///     首次穿越到 0 / 1 时震。
    ///
    /// 关于"硬件键在边界持续按"的原生 HIG 行为：iOS 原生在到顶后再按
    /// 音量加键仍会震动一下（"你已经到顶了"提醒）。我们能否复刻取决
    /// 于 KVO 是否在那种"按了但 outputVolume 值没真正变"的情况下还
    /// 触发投递。实测可能是：iOS 在边界按键时让 outputVolume 抖动一下
    /// （1.0 → 0.999 → 1.0），那 crossedBoundary 会自然 catch 每次按键。
    /// 如果未来真机验证发现硬件键在边界再按不震，说明 KVO 不会投递这种
    /// "假抖动"，到时再考虑别的信号源（如直接监听 UIPress 事件等）。
    private func crossedBoundary(oldVolume: Float, newVolume: Float) -> Bool {
        let hitMax = newVolume >= 1.0 - Self.boundaryEpsilon
            && oldVolume < 1.0 - Self.boundaryEpsilon
        let hitMin = newVolume <= Self.boundaryEpsilon
            && oldVolume > Self.boundaryEpsilon
        return hitMax || hitMin
    }

    /// 受 50ms 硬节流的 haptic 触发。返回是否真的 fire（让调用方按需更新基准）。
    /// 节流防 CC 极速滑造成 burst 轰鸣，原生硬件键节奏 ~100ms，50ms 不卡合法路径。
    @discardableResult
    private func fireHapticThrottled() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= Self.hapticMinInterval else {
            return false
        }
        hapticGenerator.impactOccurred()
        lastHapticTime = now
        return true
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
