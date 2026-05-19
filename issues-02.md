# Issue 02 — 硬件音量键在边界（max/min）持续按下时无法补回 haptic 反馈（iOS 26）

> Filed 2026-05-19. Reopen if Apple ships a public hardware-volume-key event API, or if we relax CLAUDE.md "Native Apple APIs only" on a per-feature basis.

## Problem

我们自绘 iPhone / iPad 端音量 UI 后，用隐藏 `MPVolumeView` 抑制了系统 volume HUD。Apple 把"HUD 抑制"和"硬件音量键 haptic"在同一条系统路径里捆绑了，公开 API 没有"只抑制 HUD 但保留 haptic"的单独开关 —— 所以原生 haptic 一并丢了，需要自己复刻。

通过 `AVAudioSession.outputVolume` KVO 我们能复刻三种场景：

1. ✅ 长按硬件键连续降 / 升 → 每越过 1/16 一格震一下
2. ✅ 音量首次穿越到顶 (1.0) → 震一下
3. ✅ 音量首次穿越到底 (0.0) → 震一下

**唯独这一种复刻不了**：

4. ❌ 音量已经到顶（或到底），用户再按一次硬件音量加（或减）键 → 原生 iOS 仍会震一下作为 HIG affordance（"已经到顶了"提醒）—— **我们 catch 不到这次按键事件**

## Why

iOS 公开 API **不给第三方 app 直接监听硬件音量键事件**：

| 信号源 | 在边界再按时是否投递 | 公开 API? |
|---|---|---|
| `AVAudioSession.outputVolume` KVO | ❌ 值不变就不投递 | ✅ |
| `MPVolumeView` 内部 slider `valueChanged` | ❌ 同上 | ✅ |
| `UIPress` / `pressesBegan(_:with:)` | ❌ 不传递音量键事件 | ✅（无效） |
| `UIApplication.beginReceivingRemoteControlEvents` + `remoteControlReceived` | ❌ 仅 play/pause/next/prev 等媒体控制，不含音量键 | ✅（无效） |

公开 API 路线到此为止。

之前一度推测 iOS 可能在边界再按时让 `outputVolume` "抖动一下"（1.0 → 0.999 → 1.0）触发 KVO，从而被 `crossedBoundary` 捕获。**真机验证否定了这一假设** —— iOS 26 上边界再按不会触发任何 KVO 投递。

## Private route (rejected for this iteration)

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(volumeChanged(_:)),
    name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
    object: nil
)
```

`AVSystemController` 是私有框架，但它发的这个 notification 名作为字符串使用是技术上的**灰色地带**：

- 不调用任何私有符号，纯 NotificationCenter API
- 历史上 VLC、Castro 等多个第三方音量类 app 用过这条路径
- App Review 历史上**没有大规模**因此拒过
- userInfo 提供 `AVSystemController_AudioVolumeChangeReasonNotificationParameter`（值为 `"ExplicitVolumeChange"` 时表示用户硬件键 / CC 滑块操作）和 `AVSystemController_AudioVolumeNotificationParameter`（新音量值）

**为什么本轮不走**：

1. **CLAUDE.md 红线**：仓内"Native Apple APIs only. No Electron/RN/Flutter/WebView" 没明确列私有 notification，但实质属于依赖未公开 / 不承诺行为，严格意义上违反约束
2. **审核风险非零**：Apple 可以任何时候开始拒，过去没发生不代表未来不会
3. **收益小**："边界再按震动"是一个极边缘的 HIG affordance，严肃第三方播放器（VLC / Infuse / nPlayer）也都不实装

## Decision (2026-05-19)

接受公开 API 能力上限作为当前态：

- ✅ 长按连续 → 每 1/16 震
- ✅ 首次穿越到顶 / 到底 → 震一次
- ✅ UI 拖动到顶 / 到底 → 震一次
- ❌ 硬件键已经在边界再按 → 不震（接受）

实装在 `VideoPlayer/Services/SystemVolumeManager.swift`，详见 `evaluateHaptic(oldVolume:newVolume:)` 和 `crossedBoundary(oldVolume:newVolume:)`。

## When to reopen

1. Apple 公开新 API 让第三方 app 接收硬件音量键事件（例如类似 `UIPress.PressType.volumeUp/.volumeDown`）—— 关注 WWDC 27+
2. 用户反馈这个边缘场景被频繁吐槽到值得动 CLAUDE.md 红线
3. 我们决定为本特性单独豁免 "Native Apple APIs only" 约束并接受 App Review 风险

## Workarounds explored

无 —— 公开 API 路线穷尽（见上面 4 条），私有路线被红线挡掉。

## See also

- `issues-01.md` —— SF Symbol `.rotate.byLayer` 时长 / 速度无法控制（结构性卡点：公开 API 能力 < Apple 自家组件能力）。本 issue 是同类问题的另一案例。
