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

---

## Addendum 2026-05-20 — macOS debug 窗口实测纠正"完全 inert"过早结论

为了反复核查 `.rotate.speed` 行为，做了一个独立的 macOS 调试窗口 `RotateSpeedDebugView`（commit `310b8a9` 初版，`cc167c4` 修方法论 bug；位于 `VideoPlayer/Views/Debug/`，菜单 `File → Rotate Speed Debug` 或 `⌘⇧D` 打开）。窗口里有 5 个 `.rotate` 写法 + 3 个已知可响应 `.speed` 的对照组 + 1 个手动旋转 baseline，每行套 `.id(triggerCount)` 让改 speed 后强制 re-attach effect。

### 实测结果（macOS Tahoe 26 / 等价 iOS 26）

| 行 | 写法 | `.speed` 视觉响应？ |
|---|---|---|
| R1 | `.rotate.clockwise + .repeating.speed + isActive:` | **✅ 是** —— 仅 spin 段响应，idle 间隙不响应，且约 **3× 处有 cap**（3× ≈ 20×） |
| R2 | `.rotate.clockwise.byLayer + .repeating.speed + isActive:` | **✅** 同 R1 |
| R3 | `.rotate.clockwise.wholeSymbol + .repeating.speed + isActive:` | **✅** 同 R1 |
| R4 | `.rotate.byLayer + .nonRepeating.speed + value:` | ❌ 丢弃 |
| R5 | 手动 `.rotationEffect + .animation(.linear).speed`（baseline） | ✅ |
| C1 | `.bounce + .nonRepeating.speed + value:` | ❌ 丢弃 |
| C2 | `.pulse + .repeating.speed + isActive:` | ✅ |
| C3 | `.variableColor.iterative.reversing + .repeating.speed + isActive:` | ✅ |

### 对原结论的修正

原"Conclusion (iOS 26 baseline)" 那句「`.rotate.byLayer` cycle 时长视为系统固定值」**以偏概全**了。准确版本：

- **Discrete 路径**（`.nonRepeating + value:`）：`.speed` 确实被丢弃 —— 这是原 14 次尝试**全部**走的路径，所以早期 14 步**全部失败有合理性**，但当时下"对所有 .rotate 路径都 inert"的结论太大了。
- **Indefinite 路径**（`.repeating + isActive:`）：`.speed` **真生效**，但有两条隐性限制：
  - **Idle 段硬编码**：`.rotate` 一个 cycle = "spin 段 + idle 段"，`.speed` 只调 spin，idle 间隙不动。公开 API 没有 `.continuous` / `.noIdle` / `.idleDuration` 之类的开关。
  - **Speed cap**：约在 3× 处封顶。`.speed(20)` 视觉等于 `.speed(3)` —— 这也解释了原 commit `98ed6cf` 极值测试"看不出差别"被误判为 inert 的现象。
- 结论的可移植性：以上仅在 macOS 26 / 等价 iOS 26 上验证。早期 iOS 17/18 的行为未重测。

### Apple TV 实现路径推断（巩固上一条 addendum）

Apple TV 的 skip 按钮要同时满足：
- byLayer 锁数字 ✅
- 无 idle 连续旋转 ❌（公开 API 不行）
- 速度可控、无 cap ❌（公开 API cap 在 3×）

公开 API 任意两条可拿，三条不可同得。Apple 必然有 idle / cap / cycle-duration 的私有旋钮 —— 要么走 CAPackage 资源（idle/spin keyframe 直接画在 `.capackage` 里），要么走 `NSSymbolRotateEffect` 的私有属性。**两条都被 CLAUDE.md "Native Apple APIs only" 红线挡掉。**

### Future solution — 路线 X（已设计，未实装；待真实需求触发再做）

如果未来用户反馈当前 `b8503b6` 的 idle 间隙刺眼到值得动 UI，**放弃 `.symbolEffect(.rotate.byLayer)`**，改为手动 `.rotationEffect` + 拆层视觉模拟 byLayer：

```swift
ZStack {
    // 纯箭头层 —— SF Symbols 里存在 "arrow.trianglehead.clockwise"
    // 和 "arrow.trianglehead.counterclockwise"，可独立旋转
    Image(systemName: spinDirection == .clockwise
        ? "arrow.trianglehead.clockwise"
        : "arrow.trianglehead.counterclockwise")
        .font(.system(size: arrowFontSize, weight: .semibold))
        .rotationEffect(.degrees(angle))
        .animation(
            .linear(duration: targetCycleDuration)
                .repeatForever(autoreverses: false),
            value: isSpinning
        )

    // 数字静态覆盖 —— 字号 / 字重 / kerning 要肉眼调到接近 SF Symbol
    // 原版 "10.arrow.trianglehead.clockwise" 内嵌的 "10" 样式
    Text("10")
        .font(.system(size: digitFontSize, weight: .semibold))
        .foregroundStyle(.white)
}
```

**获得**：
- ✅ 无 idle（`.repeatForever` 是真正连续）
- ✅ speed 完全可控、无 cap（`Animation.speed` 没有 3× 限制）
- ✅ 可打断、可加速（toggle `isSpinning` / 改 `targetCycleDuration`）
- ✅ byLayer 视觉（数字静态）

**代价**：
- ⚠️ 字距/字号/字重需肉眼对齐 SF Symbol 原版的 "10"，没有 API 拿原版的精确 metrics
- ⚠️ 失去 `.symbolEffect` 在数字层的级联能力（不能给 "10" 加 `.bounce` 之类）—— 数字本来也不该 bounce，可接受
- ⚠️ direction 切换要换 systemName（顺时针 / 逆时针箭头是两个独立符号）
- ⚠️ iPhone / iPad / portrait / landscape 各尺寸都得目视微调对齐

**工程量**：约 50–100 行改动集中在 `iOSPlayerControls.swift` 的 skip 按钮处；额外做一个 `LayeredSkipIcon` View 复用顺/逆方向。视觉 QA 至少 4 个组合。

**触发条件**：用户反馈 idle 间隙刺眼 / 连续点击 skip 时质感被打断。**未触发前不动**，issues-01.md 当前结论 + 当前 `b8503b6` 状态 = 选项 A 仍然 hold。
