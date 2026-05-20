# TODO — iOS Player 体验完善

> 本文档是 iOS 播放器下一轮迭代的工作清单。AGENTS.md 的硬约束（Liquid Glass、MVVM、Native-only、Scope Discipline）全部适用。

---

## Source — 用户原文（不要改动此段）

> 写一个 TODO.md 根据我例举的细化，只写这个 md 文件，不修改代码，有些你无法确定的，请询问我确定具体细节：
> - 音量条 bug fix（在写了后台同步和手触之后，前台用按键更改音量，音量条不动，未同步，但实际音量已更改）
> - 音量条弹出效果（当改变音量值的时候）
> - 竖屏 bug fix（顶部三个 pill 在灵动岛下，没有规避）
> - 媒体控制面板激活/失焦效果，顶部和底部增加向上向下动画
> - 媒体控制面板 bug fix（连按按钮不会再次聚焦媒体控制）
> - 进度条的物理影响&牵动回弹动画效果。手指上下/左右移动，可以造成对进度条（和数字这整一个容器）的物理晃动效果。左右明显，上下不明显
> - 手势控制（左屏：长按 - 0.5x 减速（并呼出速度面板 pill），上下滑 - 调整亮度，连点 - 回退 10s。右屏：长按 - 2x 加速（并呼出速度面板 pill），上下滑 - 音量，连点 - 跃进 10s。底部 1/3 区域：左右滑 - 激活进度条，并移动进度条，上滑（无论在媒体控制面板还是视频播放）呼出简介面板
> - 速度面板 pill：位于顶部中心，显示 0.5x 1x 2x 3x（当前速度用液态玻璃按钮选中） 当呼出时，手指左右滑动一定 pt 切换速度。
> - 简介面板，浮动在视频底部区域，增加一个向上的灰色遮罩，如 Apple TV，左边显示视频缩略图，和 视频标题、文件信息。右边功能按钮（暂定）
> - 媒体控制面板增加一个新的功能pill： 包含变速和字母按钮。位于右下进度条上。
> - PIP 小窗，airplay 等功能实

---

## 已确认的关键决策（来自本轮问答）

- **「字母按钮」= 字幕按钮**（typo）。
- **长按变速**：手指松开 → **恢复原速**（不是 1x；记录按下前的速度并回退）。
- **连点跳秒**：**双击 1 次 = 10s**，短时间内连续双击 **累加**（10 → 20 → 30 …）；并在 HUD 中显示累计值。
- **简介面板缩略图**：**视频首帧 / 海报帧**（启动后静态，不随播放进度变化）。
- **简介面板右侧按钮集合**：保留位，**待确认**（见 §9）。

---

## 1. 音量条 bug fix — 硬件键 → UI 不同步

**现象**：前台用硬件音量键调整时，实际系统音量已变，但播放器内自绘的音量条 UI 不动。

**根因猜测**（待真机/LLDB 验证）：
- `SystemVolumeManager.observeSystemVolume()` 的 KVO 在前台理论上会触发，但 UI 层（`volumePill` / iOS 自绘音量条）可能没把 `SystemVolumeManager.shared.volume` 作为 `@Observable` 依赖读出来，于是值变了 View 不重绘。
- 也可能：自绘 UI 读的是 `PlayerViewModel.systemVolume`（`PlayerViewModel.swift:34` 附近的 computed property），但 `PlayerViewModel` 本身没 observe `SystemVolumeManager` 的变化 → View body 不会因为 KVO 触发而重新计算。

**实现要点**：
- 在 `iOSPlayerControls` 的 `volumePill` 里直接 `@Bindable`/读取 `SystemVolumeManager.shared`，让 `@Observable` 的依赖追踪生效。
- 或在 `PlayerViewModel` 持有 `SystemVolumeManager` 实例并暴露 `var systemVolume: Float { manager.volume }` 时确保 manager 是 `@Observable` 引用（当前 `shared` 是 singleton，需要确认 View 是否真正 subscribe 到了它的属性写入）。
- 排查时打点：在 `setupVolumeView()` 完成后立刻 `print(volume)`，并在 KVO closure 里打 `print("KVO ->", newVolume)`，对照 UI 是否重绘。

**验收**：
- 后台改音量 → 回前台：UI 与系统一致（已有的 `resyncWithRetries` 保证）。
- **前台**按硬件键改音量：UI 立刻变化，**无掉帧 / 无回弹**。
- 自绘音量条拖动：与手指 1:1，松手不抖动（已有的 `isUserInteracting` 行为不退步）。

---

## 2. 音量条「弹出」效果（变化时短暂呈现）

**目标**：音量值变化时（硬件键或拖动），音量条从顶部 pill 区轻盈材质化弹出，停顿数秒后自动隐藏；行为对标系统 HUD 但视觉走 Liquid Glass。

**实现要点**：
- 触发源 = `SystemVolumeManager.volume` 变化。建议在 `iOSPlayerControls` 用 `.onChange(of: volume)` 把一个本地 `@State var volumeHUDPresented = false` 翻到 `true`，并启动 cancellable Task，N 秒后翻 `false`。
- 呈现：`.glassEffectTransition(.materialize)`，参考 `glass-know` skill。形态：横向 capsule，含图标 + 数值条 + 百分比。
- 位置候选：① 顶部三 pill 之一替换/扩展；② 屏幕正上方独立浮层。**待确认**。
- 与控制面板的关系：音量 HUD 独立显示，**不**触发媒体控制面板 5s 倒计时（避免硬件键操作意外把面板拉起）。

**待确认**：
- (a) 弹出位置：替换 `volumePill` 原位，还是从屏幕上沿独立浮出？
- (b) 自动隐藏时长：建议 1.5s，需确认。
- (c) 媒体控制面板已可见时，是否仍单独弹音量 HUD？建议「不弹，让 pill 自身高亮即可」。

---

## 3. 竖屏顶部 pill 规避灵动岛

**现象**：竖屏下 `topBar` 的三个 pill（`utilityPill` / `volumePill` / 其他）位置贴顶，与灵动岛重叠。

**实现要点**：
- `iOSPlayerControls.swift:85-86` 当前已写 `.padding(.top, isCompactHeight ? 8 : 12)` + `.safeAreaPadding(.top)`。竖屏下 `safeAreaPadding(.top)` 应已避开状态栏，但灵动岛设备的 safe area 顶部插入值实测要 ≥ 59pt，需用真机/对应模拟器（iPhone 15+/16+/17 Pro）验证。
- 若 safe area 已足够，可能问题是 `topBar` 本身的视觉中心与灵动岛宽度（约 122–125pt 居中）撞上 → 居中那个 pill（`utilityPill`）需要让位。
- 方案候选：
  - **A**（推荐）：让顶部三 pill 在竖屏下整体下移到 dynamic island 之外，并将 `utilityPill` 从「居中」改为「居左/居右」，避免与岛同 X。
  - **B**：动态读取 `UIScreen.main.displayCornerRadius` + `safeAreaInsets.top`，按值决定 padding。

**验收**：
- iPhone 15 Pro / 16 / 17 Pro 竖屏：三 pill 与灵动岛无视觉重叠、无遮挡触发。
- 横屏：无回退（横屏没有岛）。
- iPad：无回退。

**待确认**：方案 A 还是 B；A 的情况下 `utilityPill` 居中改成哪一侧。

---

## 4. 媒体控制面板 激活 / 失焦动画（向上 / 向下推入）

**目标**：面板呼出时，顶部 bar 从屏幕上沿下落、底部 bar 从下沿上推；隐藏时反向出去。配合 `.glassEffectTransition(.materialize)` 同步释放/消散。

**实现要点**：
- 现状（`iOSPlayerControls.swift:72-96`）：`topBar` / `bottomBar` 通过 `viewModel.isControlsVisible` 直接控制可见性，没有方向化的 enter/exit。
- 改造：
  - `topBar` 加 `.transition(.move(edge: .top).combined(with: .opacity))`。
  - `bottomBar` 加 `.transition(.move(edge: .bottom).combined(with: .opacity))`。
  - 包一层 `withAnimation(.spring(response: 0.45, dampingFraction: 0.85))` 在 `viewModel.toggleControls()` 内。
  - 玻璃材质继续走 `.glassEffectTransition(.materialize)`，与 transform 同时进行（已是当前架构）。
- 与第 5 项「连按按钮重新聚焦」共用同一个 spring 曲线，保证视觉一致。

**验收**：
- 单击空白处呼出：top 下落、bottom 上推，玻璃同步释放。
- 5s 倒计时到：反向退出。
- 期间手势（scrub / 拖音量）不应破坏动画（已有 `isScrubActive` gate）。

**待确认**：spring 参数（response/damping）按当前推荐落地，后续若与设计感觉不符再调。

---

## 5. 媒体控制面板 bug fix — 连按按钮不会再次聚焦

**现象**：媒体控制面板已可见时，用户连续点击控制按钮（播放/暂停/前进/后退等），自动隐藏倒计时**不会被刷新**，导致按到一半面板就消失。

**根因**（`PlayerViewModel.swift:299-348`）：
- `autoHideTask` 在面板呼出后启动 5s 倒计时。当前的 `togglePlayback()` / `skipForward()` / `skipBackward()` 等按钮 action 内部似乎没有调用 `scheduleAutoHide()` 重置。
- 需要逐个 action 审计：每次按钮交互（不是单纯触摸空白处），都应 `autoHideTask?.cancel()` + 重新 `scheduleAutoHide()`，等价于「用户还在交互，倒计时归零」。

**实现要点**：
- 在 `PlayerViewModel` 暴露一个 `userInteracted()` 方法（仅做 `cancel + scheduleAutoHide`），所有按钮 action 末尾调用一次。
- 或在 View 层统一拦：给 `topBar` / `bottomBar` 加 `.onTapGesture { vm.userInteracted() }`（注意不能吃掉按钮自己的 tap，需要 simultaneous gesture）。

**验收**：
- 面板可见 → 连点 3 次播放按钮 → 面板 **不**在第一次按钮按下后 5s 消失，而是在 **最后一次按下** 后 5s 才消失。
- 拖进度条 / 拖音量条同样不让面板提前关。

---

## 6. 进度条 物理 / 牵动 / 回弹动画

**目标**：手指拖动时，进度条（含左右时间数字这「整一个容器」）作为一个有惯性的物体，被手指方向「拖」出一点位移，松手后弹性归位。

- **左右方向**：明显位移（建议 ≤ 12pt），跟手；松手回弹（spring response 0.35 / damping 0.7）。
- **上下方向**：弱位移（建议 ≤ 4pt），更克制；同 spring。
- 容器范围：进度条 + 左右时间标签（已经是同一 HStack）一起整体平移，不要单独动条。

**实现要点**：
- 新增 `@GestureState var trackDrag: CGSize` 跟随手指 translation，`.offset(...)` 应用到含进度条 + 标签的容器。
- 阻尼曲线：`offset = translation * dampingCurve(distance)`，远端衰减（参考 iOS rubber-banding：`offset = c * d / (c + d)`，c≈40）。
- 与 `isScrubbing` 的 seek 行为并行：seek 仍按横向 translation 计算，**视觉位移**只是叠加在容器变换上，不影响 seek 数学。
- 玻璃材质这一刻应处于 `isGlassVisible == false`（scrubbing 中），物理位移只作用在文字 + 进度条本体，不影响 glass 容器（已经被材质化消散）。

**验收**：
- 手指拉左 50pt → 容器轻微左移，但 seek 仍按 50pt 等比换算。
- 松手 → 弹性回到原位，无超调或过度晃动。
- 上下方向手感存在但极弱。

**待确认**：是否需要 haptic 在松手回弹瞬间叠一下（建议无，避免过载）。

---

## 7. 手势控制（核心交互重构）

整张屏幕按区域划分；所有手势仅在播放期生效；与现有 tap-to-toggle、scrub gesture 不冲突。

### 7.1 区域定义

- **左半屏**（屏幕左 1/2，且 **不在底部 1/3** 内）：
  - 长按：**0.5x 减速**，同时**呼出速度面板 pill**（§8）；松开恢复**按下前的原速**。
  - 单指上下滑：调整**屏幕亮度**（`UIScreen.main.brightness`），自绘 HUD 反馈（参考 §2 音量 HUD 同风格）。
  - 双击：**回退 10s**，连续双击累加（10 → 20 → 30 …）；HUD 显示累计值。
- **右半屏**（屏幕右 1/2，且 **不在底部 1/3** 内）：
  - 长按：**2x 加速**，呼出速度面板 pill；松开恢复原速。
  - 单指上下滑：调整**系统音量**（走 `SystemVolumeManager.setUserVolume`）。
  - 双击：**前进 10s**，连续双击累加。
- **底部 1/3 区域**（贯穿左右整宽）：
  - 单指左右滑：激活进度条（等价 scrub 进入），手指随动；与现有 `isScrubbing` 流统一入口。
  - 单指上滑：**呼出简介面板**（§9）。**全屏（无论控制面板是否可见）**都生效。

### 7.2 实现要点

- 单一 `DragGesture(minimumDistance: 0)` + 起点定位区域，避免多个 DragGesture 互抢。
- 长按建议用 `LongPressGesture(minimumDuration: 0.35)` 串联 → 进入 hold 态切速度；hold 释放回退原速。
- 双击 = `TapGesture(count: 2)`；累加状态机：N 次双击在 window（建议 600ms）内则 `accumSkip += 10`，window 内无新双击则 commit + 重置。
- 上下滑亮度 / 音量：触发阈值 8pt；之后线性映射，整屏高度 = 0→1。
- 区域判定：`onGeometryChange` 已有 `screenSize`；落点 `value.startLocation` 即可分区域。

### 7.3 与现状的冲突

- 现有 `iOSPlayerControls` 的 `isScrubbing` / `isVolumeScrubbing` / `inertiaTask` 已在底部进度条 + 右侧音量区做了一套逻辑（见 `iOSPlayerControls.swift:12-19`）。**新手势体系上线需把这些迁移到统一手势分发器**，避免双套并存。
- Tap-to-toggle 控制面板：保留**单击空白**（非按钮、非进度条）= toggle controls。**单击不能与双击相打架**：用 `simultaneously` + `count: 2 wins` 规则。

### 7.4 验收

- 每种手势单独可触发，互不串扰。
- 长按变速：手指仍在屏 → 速度持续；离屏 → 恢复原速；按下前是 1.5x → 离屏回 1.5x，**不是** 1x。
- 双击连续累加 HUD 数字正确（10 / 20 / 30…）。
- 底部上滑唤出简介面板，在「控制面板可见」和「不可见」两种状态下都生效。

### 7.5 待确认

- (a) 亮度调整是否只影响**应用内画面亮度**（自绘 overlay）还是直接改**系统亮度**（`UIScreen.brightness`，会持久化）？建议改系统亮度但记录原值，App 退出时复原。
- (b) 双击累加 window 长度（默认 600ms，是否合适）。
- (c) 底部 1/3 区域上滑唤出简介面板时，是否也算「用户交互」从而刷新自动隐藏倒计时？

---

## 8. 速度面板 pill

**位置**：屏幕顶部中心，与 `topBar` 同高度。

**内容**：横向 4 个挡位 — 0.5x / 1x / 2x / 3x。当前速度对应的按钮以**液态玻璃高亮**（参考 `glass-know`，用 `glassEffectID` 让被选中的按钮材质化）。

**触发**：
- 用户长按左屏 → 自动呼出（同 §7.1）。
- 用户在媒体控制面板的「新功能 pill」（§10）点击速度按钮 → 也呼出。

**交互**：
- 呼出后，手指**继续按住** + 左右滑动，每滑过 N pt（建议 60pt）切到相邻挡位。
- 松手 → pill 保持 1s 后消散；选中的速度立即生效。
- 当前长按场景（§7）下的「松手恢复原速」与本 pill 的「手指松开后保留所选速度」**互斥**：长按变速时**不允许同时左右滑挡位**（hold 阶段优先），仅当用户通过 §10 入口主动开 pill 才进入挡位选择模式。

**实现要点**：
- 用 `GlassEffectContainer` + 4 个 `GlassButton`，选中态走 `.glassEffectTransition(.materialize)`。
- 出现/消失同 §4 的 spring 曲线。

**待确认**：
- (a) 是否要支持「拖到挡位之间」做线性插值（如 1.5x），还是仅 4 个离散挡位？建议**仅 4 挡**。
- (b) 1s 自动消散是否合适。

---

## 9. 简介面板（Apple TV 风格底部浮层）

**外观**：
- 浮动在视频底部 1/3 区域。
- 顶部加**向上的灰色遮罩渐变**（黑→透明），让上方画面与文字区域过渡，避免文字浮在亮场景上不可读。参考 Apple TV、Apple Music「现在播放」详情页的渐变手法。
- 左：**视频缩略图**（首帧 / 海报帧；启动时取一次缓存，不随进度变化）+ 视频**标题**（文件名去扩展名）+ **文件信息**（分辨率、时长、文件大小、可能的编码）。
- 右：**功能按钮组**（具体集合待确认，见下）。

**触发**：
- 屏幕底部 1/3 区域上滑 → 唤出。
- 再次下滑 / 点击空白 → 收起。

**实现要点**：
- 新文件：`VideoPlayer/Views/InfoPanel.swift`，无业务逻辑，纯展示 + intent 回调。
- 数据由 `PlayerViewModel` 提供：`currentVideoTitle: String`、`currentVideoMeta: VideoMeta`（新增简单 struct：resolution / duration / fileSize / codec）。
- 缩略图：`AVAssetImageGenerator` 取 `CMTime.zero` 帧，cache 到 `RecentVideo` 关联或临时内存。
- 遮罩：`LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top)` 叠在面板上方 80pt 高度。
- 玻璃：面板**主体**走 Glass 材质（`GlassPanel`），灰渐变只在面板上沿做羽化过渡。

**待确认 — 右侧功能按钮集合**（用户表示「暂定」，请明确）：
候选：① 字幕轨道切换 ② 音轨切换 ③ 速度 ④ AirPlay ⑤ PIP ⑥ 章节 / 书签 ⑦ 分享 ⑧ 在 Finder 打开（macOS 没有，iOS 不适用，可移除）⑨ 从「最近」中移除。**请用户选一个组合**。

---

## 10. 媒体控制面板 — 新功能 pill（变速 + 字幕）

**位置**：右下进度条**之上**（与左下时间标签对称，但放在进度条容器外侧的右上位置；具体 anchor 待确认）。

**形态**：横向 capsule，包 2 个 `GlassButton`：
- 左半：**变速** — 显示当前速度文字（如 `1x`），点击呼出 §8 速度 pill。
- 右半：**字幕** — 图标 `text.bubble` 或 `captions.bubble`；点击弹出字幕轨道菜单（或开关，视轨道数）。

**实现要点**：
- 复用 `iOSPlayerControls.swift:137-159` 的 `glassPillBackground` 风格。
- 字幕逻辑暂时只做 UI 占位 + 已有轨道枚举；AI 字幕生成接入是另一条独立工作流，不在本 TODO 范围。

**待确认**：
- (a) 是否要在变速按钮上显示当前速度的小数字（动态），还是只放一个图标 `gauge`？建议显示数字。
- (b) 没有可用字幕轨道时，字幕按钮是 disabled、半透明，还是直接隐藏？

---

## 11. PIP（画中画） & AirPlay

**目标**：标准 AVKit 实现，绑入 §10 新功能 pill 或简介面板右侧按钮。

**实现要点**：
- PIP：`AVPictureInPictureController`，需要 `AudioSessionManager` 把 audio session category 设到 `.playback` 并 `mixWithOthers` 视需求；layer 取自 `AVPlayerEngine` 的 `AVPlayerLayer`。
- AirPlay：`AVRoutePickerView` 包一层 `UIViewRepresentable`（项目里已经有 `MPVolumeView` 包装的先例，参照风格写一个 `RoutePickerView`）。
- 后台播放 entitlement：`Info.plist` 需要 `UIBackgroundModes: audio` （若启用后台播放）；与 PIP 是不同的开关。
- 锁屏控制中心：可考虑同步把 `MPNowPlayingInfoCenter` 元数据填进去（视频标题、当前位置），让锁屏 / 控制中心也能看到。

**验收**：
- PIP：从全屏播放进入 PIP（按按钮 / App 后台），从 PIP 拖回 App。
- AirPlay：检测可用设备，picker 正确弹出，路由切换后音视频均走外设。

**待确认**：
- (a) PIP / AirPlay 入口同时放在 §10 新功能 pill 和 §9 简介面板，还是只放一处？
- (b) 是否启用后台播放（影响电池/审核口径）？

---

## 优先级建议（供讨论）

1. **P0（修 bug，先做）**：§1 音量条同步、§3 灵动岛规避、§5 媒体控制面板焦点。
2. **P1（基础体验）**：§4 面板进出动画、§2 音量 HUD、§10 新功能 pill（不含 AI 字幕逻辑）。
3. **P2（核心交互重构）**：§7 手势体系、§8 速度面板。
4. **P3（增强）**：§6 进度条物理回弹、§9 简介面板、§11 PIP/AirPlay。

> 顺序非强制；§7 手势体系会影响 §1–6 的事件路由，所以如果决定大改手势，建议把 §7 提到 §4–6 之前一起做。

---

## 全局技术债 / 注意事项

- 手势重构（§7）会让 `iOSPlayerControls.swift` 736 行进一步膨胀。建议拆 `iOSGestureLayer.swift` 单独承载分发逻辑，View 只保留视觉。
- 所有新 HUD（音量、亮度、累计跳秒、速度）都应共享一个底层组件：`TransientHUD` —— 同样的 Glass 材质、同样的 fade timing、同样的 transition；散写会导致动画曲线 / 余光时间不一致。
- 玻璃材质的统一闸（`isGlassVisible`，`iOSPlayerControls.swift:34`）需要把新 HUD / 简介面板 / 速度 pill 全部纳入：scrub 期间这些都应同步消散。
- 已知遗漏（用户原文最后一行被截断）：「PIP 小窗，airplay 等功能实」— 实**现** / 实**装**？按完整语意已纳入 §11。如果还有别的 idea（"实时" "实验" 等？）请补充。
