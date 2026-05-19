# Issue 01 — Skip-button rotation: cannot control SF Symbol `rotate.byLayer` duration / speed (iOS 26)

> Filed 2026-05-19. Reopen when SF Symbol API evolves.

## Problem

iPhone / iPad 端的 forward / backward 跳转按钮（`10.arrow.trianglehead.{clockwise,counterclockwise}`），希望像 Apple TV 那样：

1. **byLayer** 旋转 —— 只有箭头层旋转，"10" 数字保持不动。
2. 单次旋转的**时长 / 速度可控**（目标 ~0.12s，期望可在代码里调）。
3. **可打断 + 视觉加速** —— 连点要立刻有反馈、视觉上变快。
4. **最后一次点击的动画完整播完** —— 不能被衰减或外部取消。

(1)、(3)、(4) 都能做到。**唯独 (2) 做不到** —— SF Symbol `.rotate.byLayer` 的内在 cycle 时长在 iOS 26 是 Apple 平台层面**强制固定**的，任何已知公开 API 都无法改动它。

## What we tried (chronological)

| Commit  | Approach | Result |
| ------- | -------- | ------ |
| `52eadfd` | `.symbolEffect(.rotate.clockwise, options: .nonRepeating.speed(...), value:)` — whole-symbol | `.speed` 视觉无效 |
| `9fb2d62` | + streak counter + `.speed(base + step·streak)` | `.speed` 无效；streak 节奏脱节 |
| `da89197` | 手动 `rotationEffect(.degrees)` + `withAnimation(.easeOut(duration:))` | **speed 真正生效**，但**失去 byLayer**（"10" 跟着转） |
| `4bbab74` | `.symbolEffect(.rotate.byLayer, value:)` — 第一次 byLayer | 旋转正常，未尝试控速 |
| `c4254c5` | 把 `.speed` 从 `PlayerViewModel.buttonSeekAnimationDuration` 推导 | `.speed` 无效 |
| `41ca9ac` | 字面值 `.speed(5.0)` | `.speed` 无效 |
| `dab0b5a` | 解耦 rotation target 与 scrubber tween | `.speed` 无效 |
| `56b363d` | `.repeating.speed(5) + @State isActive + stop-Task` | `.speed` 无效 |
| `b605689` | + tap-count session 数学，speed 随连点 ramp | `.speed` 无效；数学正确，视觉打平 |
| `b8503b6` | 退回 discrete `.nonRepeating, value:` + 每 tap spring scale pulse | 旋转用系统默认速度；pulse 给 Apple-TV 式触感 ✓ |
| `d0e1aba` | `.repeat(.periodic(1)).speed(...)` + `withAnimation(.linear(duration:))` 包 trigger | 两路都无效 |
| `98ed6cf` | 极值（speed 20×、duration 0.05s）排除「数值太小看不出」 | 仍无变化 → 证明两路都 inert |
| `27f31af` | `UIViewRepresentable` 包 `UIImageView`，调 `addSymbolEffect(.rotate.byLayer, options: .nonRepeating.speed(speed))` | UIKit 路径 `.speed` 同样无效 |
| `28389a3` | UIKit 切到 `.repeating.speed(speed)` + `DispatchWorkItem` 在 `baseline/speed` 秒后 `removeAllSymbolEffects` | 仍无变化 |

## Conclusion (iOS 26 baseline)

Apple 的 SF Symbol effect engine 把 `.rotate.byLayer` 的 cycle 时长**视为系统固定值**。`SymbolEffectOptions.speed(_:)` 文档里写着对 discrete effect 无效；实测在 indefinite / repeating 路径下对 `.rotate.byLayer` **也**无效。这一限制**横跨 SwiftUI 和 UIKit**。Apple TV / `AVPlayerViewController` 内部能拿到的 cycle 控制接口要么走私有 API，要么用了不同的 effect 类型 —— 我们当前没办法用公开 API 复刻。

## Empirical timing

- `.rotate.byLayer` one full cycle at speed=1 measured **~1.7s** on iOS 26 (user-verified). Used as `iOSPlayerControls.rotateCooldown` to prevent rapid taps from queueing trailing rotations.

## Workarounds explored

- **视觉欺骗**（`b8503b6` 落地）：每 tap 用 discrete `value:` 触发一次 byLayer 旋转 + 一个 spring scale pulse。控不了 cycle 时长，但每次 tap 都有清晰物理反馈；连点时多个 cycle 自然叠加，视觉上算"快"。**这是目前最干净的 SwiftUI 实现**。
- **放弃 byLayer**（`da89197` 落地）：用 `rotationEffect(.degrees(angle))` + `withAnimation`。speed 完全可控，代价是"10" 数字跟着箭头一起转。

## Future-resolution paths

1. **关注未来 SDK**：留意 `SymbolEffectOptions.duration(_:)` 或类似的 cycle-timing API。WWDC 26+ 可能扩充。
2. **逆向 SF Symbol 私有 API**：`NSSymbolRotateEffect` 可能有非公开属性可以塞进 `setValue(forKey:)`。脆弱且 App Review 风险。
3. **绕开 `.rotate` effect**：用 `phaseAnimator` / `KeyframeAnimator` 直接驱动 `transform3D` 在某些 sublayer 上 —— 需要拿到 SF Symbol 渲染出的 CAShapeLayer 树，目前没有公开访问。
4. **Apple Feedback**：提交 FB 引用本 issue。

## Current state on `main`

Reset to `b8503b6` 的 `iOSPlayerControls.swift`：

- `.symbolEffect(.rotate.{clockwise,counterClockwise}.byLayer, options: .nonRepeating, value: trigger)` —— 每 tap 触发一次 byLayer 旋转，系统默认速度。
- 每 tap 同时跑一个 `withAnimation(.spring(response: 0.28, dampingFraction: 0.55))` 把 scale 从 0.88 弹回 1.0 —— 物理反馈层，独立于 symbol effect。
- "10" 数字保持不动。

## Comparison branches (local, not pushed)

| 分支 | 指向 | 简述 |
|---|---|---|
| `try/v1-initial-apple-tv-style` | `52eadfd` | 第一版 Apple-TV-style 改造，whole-symbol rotate（"10" 跟着转） |
| `try/v2-first-byLayer` | `4bbab74` | 第一次启用 byLayer，无 pulse，纯系统旋转 |
| `try/v3-best-feel-current` | `b8503b6` | byLayer + per-tap spring pulse（当前 main 状态） |

`git checkout try/<name>` → build → 目视比较 → 选最佳。

---

## Addendum 2026-05-19 — Apple 一线组件视觉精致度差距的根因推测

在做音量胶囊 UI/UX 那一轮（commit `ca595f2` / `50a47cc`）时，回头讨论了 Apple TV 音量 mute 斜线的"绘出"动画 —— 进一步意识到我们这条 skip-rotate 卡点很可能不是孤立问题，而是同一类「公开 API 能力 < Apple 自家组件能力」的具体案例。归档讨论结论：

### 三条相互印证的证据

1. **逻辑闭合**：iOS 26 公开 API 不暴露 `.rotate.byLayer` cycle 时长 → 第三方做不到。Apple 自家做到 → Apple 用的不是这套公开 API。本 issue line 37 已经写下"走私有 API，要么用了不同的 effect 类型"，下面把"不同的 effect 类型"具体化。

2. **行业旁证**：严肃第三方播放器（VLC / Infuse / nPlayer）的 skip 动画**都**和系统差一截。这种集体缺失最经济的解释是公开 API 缺一块，而不是大家都没动脑。

3. **Apple 自家 app 同一图标视觉略异**：Apple Music / Control Center / Apple TV Remote 三个 app 里 mute 斜线长得**略有差异** —— 同一公开 API 调用不可能产出不同视觉，更支持"各自带自己的资源"。

### 最可能的 Apple 内部实现路径（按概率排序）

| 路径 | 描述 | 第三方可复刻？ |
|---|---|---|
| **CAPackage / `.capackage`** | QuartzCore SPI，矢量动画 + 状态机打包为资源文件。AVPlayerViewController 内部 bundle 里历史上能 dump 到 `.ca` / `.capackage` 资源。给图标的每一层（旋转箭头、斜线 stroke、波纹）做独立 keyframe + timing curve。 | ❌ SPI，App Review 风险 |
| **私有 SymbolEffect SPI** | `NSSymbolRotateEffect` / `NSSymbolReplaceEffect` 可能有非公开属性（duration / curve）。Apple 自己读写，公开 API 不暴露。 | ❌ private API，脆 |
| **完全自绘 + 视觉对齐 SF Symbol** | UIKit `CAShapeLayer` + UIBezierPath，独立动画，外观与 SF Symbol 像素级对齐。开发成本高。 | ⚠️ 工程量大但合规 |
| **三者混用** | 旋转走私有 SymbolEffect、斜线走 CAPackage、波纹走 SF Symbol —— 不同动画选最合适的工具。 | ❌ |

### 对本 issue 的最终态判断

- 公开 API 路线已穷尽（见上面 14 条尝试表），**不再尝试**
- 私有 API / CAPackage / SPI 路线**永久不走**：违反 App Review 红线 + 违反本仓 CLAUDE.md "Native Apple APIs only" 硬约束
- 当前 `b8503b6` 的「discrete byLayer rotate + 1.7s cooldown + 独立 bounce trigger」**接受为最终态**，直到：
  - WWDC 27+ 公开 `SymbolEffectOptions.duration(_:)` 或类似 cycle-timing API；或
  - Apple 把 CAPackage runtime 或部分私有 SymbolEffect 属性公开

### 行业惯例佐证

业内对这类卡点的主流解法是：

1. **接受公开 API 上限**（大多数 app 走这条）
2. **完全自绘**（VLC 等高定制 app 走这条，工程量大）
3. **Rive / Lottie**（设计 + 工程协作，但与"Native Apple APIs only"冲突，本仓不走）

我们选 (1)。本 addendum 的存在是为了避免未来接手人重走 14 步死路。
