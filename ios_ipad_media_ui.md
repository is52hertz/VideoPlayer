# iOS/iPadOS Media Player UI — 交接文档

## 项目概览

| | |
|---|---|
| **平台** | macOS · iOS · iPadOS |
| **最低系统** | iOS 26.4 / macOS 26.4（Liquid Glass APIs 仅此版本起可用） |
| **架构** | View → ViewModel → PlayerEngine → AVPlayer |
| **设计语言** | Liquid Glass — Apple `.glassEffect()` 原生 API |
| **Xcode Project** | `VideoPlayer.xcodeproj` |

---

## 目录结构（仅 Swift 源码）

```
VideoPlayer/
├── VideoPlayerApp.swift
├── ContentView.swift
├── Engine/
│   ├── PlayerEngine.swift          # 协议定义
│   └── AVPlayerEngine.swift        # AVPlayer 实现
├── Models/
│   └── RecentVideo.swift
├── ViewModel/
│   └── PlayerViewModel.swift       # @Observable，所有播放状态和操作
└── Views/
    ├── PlayerView.swift             # 主播放器视图（macOS/iOS 平台分拆）
    ├── iOSPlayerControls.swift      # ★ iOS/iPadOS 控制层（本次新增，可改）
    ├── VideoSurfaceView.swift       # AVPlayerLayer 渲染（NSView/UIView）
    ├── GlassPanel.swift             # 玻璃面板容器（.glassEffect(.regular)）
    ├── GlassSlider.swift            # 自定义滑块（音量/进度，白色轨道）
    ├── GlassButton.swift            # 玻璃按钮（.buttonStyle(.glass)）
    ├── WelcomeView.swift            # macOS 专属欢迎页
    ├── WelcomeStyles.swift          # macOS 专属样式常量
    ├── WindowTrackerView.swift      # macOS 专属鼠标悬停追踪
    ├── VisualEffectBackground.swift # macOS NSVisualEffectView
    └── VideoThumbnailView.swift     # macOS 视频缩略图 + NSCache
```

---

## ViewModel 关键接口

文件：`VideoPlayer/ViewModel/PlayerViewModel.swift`

```swift
@Observable final class PlayerViewModel {
    // 状态
    var state: State        // .idle / .loading / .ready / .playing / .paused / .finished / .error(String)
    var currentTime: TimeInterval
    var duration: TimeInterval
    var isControlsVisible: Bool     // 控制层显隐（0.3s easeInOut 动画）
    var volume: Double              // 代理到 engine.volume
    var videoTitle: String

    // 操作
    func togglePlayPause()
    func seek(to time: TimeInterval)
    func seekForward(_ delta: TimeInterval)   // 默认 10s
    func seekBackward(_ delta: TimeInterval)  // 默认 10s

    // 点击处理
    func handleVideoTap()       // macOS：切换播放 + 切换控制层显隐
    func handleVideoTapIOS()    // iOS：仅切换控制层显隐（不改播放状态）
}
```

`isControlsVisible` 通过 `scheduleAutoHide()` 在 2.5 秒无操作后自动设为 false。

---

## 平台分拆方式（PlayerView.swift）

```swift
// 控制层入口
@ViewBuilder
private var controlsOverlay: some View {
    #if os(macOS)
    macOSControlsOverlay   // PlayerView 内部，500pt 宽浮动面板，可拖拽
    #else
    iOSPlayerControls()    // 独立文件，iPhone/iPad 各自分支
    #endif
}

// 点击手势
.onTapGesture {
    #if os(macOS)
    viewModel.handleVideoTap()
    #else
    viewModel.handleVideoTapIOS()
    #endif
}
```

macOS 专属 `@State` 变量（`controlOffset` / `dragStartOffset`）已用 `#if os(macOS)` 门控。

---

## iOSPlayerControls.swift — 当前实现

文件：`VideoPlayer/Views/iOSPlayerControls.swift`  
整个文件被 `#if os(iOS)` 包裹。

### 设备判断（关键坑）

```swift
// ❌ 错误：iPhone Pro Max 横屏 horizontalSizeClass == .regular（和 iPad 一样）
private var isCompact: Bool { horizontalSizeClass == .compact }

// ✅ 正确：用 UIDevice 区分 iPhone vs iPad
private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }

// ✅ 正确：iPhone 横屏检测
private var isLandscape: Bool { verticalSizeClass == .compact }
```

### iPhone 布局（iPhoneOverlay）

**Infuse 风格分布式叠层**，无面板容器：

```
ZStack
├── vignette（顶部 + 底部双向渐变晕影，allowsHitTesting: false）
└── VStack(spacing: 0)
      ├── [顶部占位] Color.clear，高度 44~56pt + safeAreaPadding(.top)
      │              未来放：关闭按钮 / 字幕 / 音频 / 音量
      ├── Spacer()
      ├── [中央] 播放按钮 HStack — 垂直居中
      │         .buttonStyle(.plain) + .foregroundStyle(.white)
      │         竖屏：spacing=48, backward/forward=26pt, play=38pt
      │         横屏：spacing=36, backward/forward=22pt, play=32pt
      ├── Spacer()
      └── [底部] 进度行 — 贴底部边缘
                HStack: 时间(minWidth:42) + scrubber + 时间(minWidth:42)
                .padding(.horizontal, 20).padding(.bottom, 16).safeAreaPadding(.bottom)
```

晕影：顶部 LinearGradient(.black.opacity(0.6) → .clear，height: 180pt)  
　　　底部 LinearGradient(.clear → .black.opacity(0.65)，height: 220pt)

### iPad 布局（iPadOverlay）

**GlassPanel 浮动面板**，与 macOS 视觉一致：
- 容器：`GlassPanel`（`.glassEffect(.regular)` — 唯一玻璃层）
- 内部按钮：`.buttonStyle(.plain)`（**不用 GlassButton**，避免玻璃嵌套）
- Row 1：音量（GlassSlider width:100）| 播放三按钮 | 占位工具图标
- Row 2：进度 scrubber（同 iPhone）
- 定位：`.padding(.horizontal, 40).padding(.bottom, 16).safeAreaPadding(.bottom)`

### 进度 Scrubber

自定义实现（不用 GlassSlider），轻量极简风格：
- 3pt 白色半透明轨道 + 白色填充进度 + 12pt 白色圆点滑块
- 拖拽命中区 28pt 高（`DragGesture(minimumDistance: 0)`）
- 时间标签 `.monospacedDigit()` 防止数字变化时布局抖动

---

## Glass 设计系统（不要修改这些文件）

### GlassPanel
```swift
struct GlassPanel<Content: View>: View {
    // 包裹内容，应用 .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
    // + 双层阴影（depth感）
}
```

### GlassButton
```swift
struct GlassButton: View {
    let systemName: String
    var fontSize: CGFloat = 18
    let action: () -> Void
    // .buttonStyle(.glass) — iOS 26+ 原生液态玻璃按钮样式
}
```
**注意：GlassButton 不能放在 GlassPanel 内部（玻璃嵌套）。iPad 控制面板内用 .buttonStyle(.plain)。**

### GlassSlider
```swift
struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    // 4pt 白色轨道 + 12pt 圆点滑块
    // 当前用于：macOS 音量 / iPad 音量
    // iPhone 进度条用独立 progressScrubber（3pt 轨道，更轻量）
}
```

---

## 重要注意事项

### 1. Liquid Glass 不能嵌套
`.glassEffect()` 和 `.buttonStyle(.glass)` 不能叠加使用（视觉会冲突）。规则：
- `GlassButton` → 单独使用，不放入 `GlassPanel`
- `GlassPanel` 内部 → 用 `.buttonStyle(.plain)` 白色图标

### 2. iPhone Pro Max 横屏 size class 陷阱
iPhone Pro Max（含 Plus 系列）横屏时 `horizontalSizeClass == .regular`，与 iPad 相同。
**必须用 `UIDevice.current.userInterfaceIdiom == .phone` 判断设备类型，不能靠 size class。**

### 3. iOS 入口（ContentView）
iOS 上目前没有 WelcomeView，用通用空白状态代替。打开视频后进入 `PlayerView`。

### 4. 平台限制
- `WindowTrackerView`：macOS 专属（鼠标悬停）
- `WelcomeView` / `WelcomeStyles`：macOS 专属
- `VisualEffectBackground`：macOS 专属（NSVisualEffectView）
- `VideoThumbnailView`：macOS 专属

### 5. 构建命令
```bash
# iOS 模拟器
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

# macOS
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer \
  -destination 'platform=macOS' build
```

---

## 待完成（iPhone 顶部区域）

参考 Infuse 截图，顶部预留区 (`Color.clear`) 未来需要填充：

```
左侧：[✕ 关闭] [字幕选择] [音轨选择]
右侧：[音量滑块] [🔊]
```

这部分当前是 `Color.clear` 占位，触发 Gemini 实现时直接替换即可。布局骨架已就位。

---

## Git 提交记录（本功能）

```
b723217 fix: use UIDevice.userInterfaceIdiom to distinguish iPhone from iPad
549be35 fix: redesign iPhone overlay to Infuse-style distributed layout
2ee7a6b feat: add iOS/iPadOS playback controls overlay
```
