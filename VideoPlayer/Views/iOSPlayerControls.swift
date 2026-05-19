#if os(iOS)
import SwiftUI
import MediaPlayer

struct iOSPlayerControls: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    @GestureState private var isScrubbing = false
    @GestureState private var isVolumeScrubbing = false
    @State private var dragStartTime: TimeInterval?
    @State private var lastDragX: CGFloat?
    @State private var accumulatedSeek: TimeInterval = 0
    @State private var isFlinging = false
    @State private var inertiaTask: Task<Void, Never>?
    @State private var lastZone: Int?
    @State private var screenSize: CGSize = .zero

    private var isScrubActive: Bool { isScrubbing || isFlinging }

    // Scale visually via `.scaleEffect` so the bar isn't squeezed —
    // the text frame keeps its base width and 16/12 magnification
    // overflows the frame. Anchor is set per-side at the call site
    // (trailing for left label, leading for right label) so growth
    // projects *outward only* (away from the bar), preserving the
    // resting-state gap and giving an Apple-TV-style "lift" feel.
    private static let timeLabelBaseSize: CGFloat = 12
    private static let timeLabelActiveScale: CGFloat = 16.0 / 12.0
    private var timeLabelScale: CGFloat { isScrubActive ? Self.timeLabelActiveScale : 1.0 }

    var body: some View {
        ZStack {
            // MPVolumeView must stay in hierarchy at all times for hardware buttons to work.
            VolumeViewWrapper()
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .accessibilityHidden(true)

            vignette
                .opacity(isScrubActive ? 0 : 1)

            VStack(spacing: 0) {
                topBar
                    .padding(.top, isCompactHeight ? 8 : 12)
                    .safeAreaPadding(.top)

                Spacer()

                playbackButtons

                Spacer()

                bottomBar
            }
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            screenSize = newValue
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isScrubActive)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: isPad ? 16 : 12) {
            glassIconButton(systemName: "xmark") {
                viewModel.closeVideo()
            }

            utilityPill

            Spacer()

            volumePill
        }
        .padding(.horizontal, isPad ? 32 : 20)
        .safeAreaPadding(.horizontal)
    }

    private func glassIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Image(systemName: systemName)
            .font(.system(size: isPad ? 18 : 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: isPad ? 28 : 24, height: isPad ? 28 : 24)
            .opacity(isScrubActive ? 0 : 1)
            .padding(.horizontal, isPad ? 14 : 12)
            .padding(.vertical, isPad ? 10 : 8)
            .contentShape(Capsule())
            .glassEffect(.clear.interactive(), in: Capsule())
            .scaleEffect(isScrubActive ? 0.6 : 1.0)
            .opacity(isScrubActive ? 0 : 1)
            .onTapGesture { action() }
            .accessibilityAddTraits(.isButton)
    }

    private var utilityPill: some View {
        HStack(spacing: 0) {
            utilityIconButton(systemName: "arrow.up.left.and.arrow.down.right") {
                // Future: handle resize
            }
            utilityIconButton(systemName: "pip.enter") {
                // Future: handle PiP
            }
        }
        .glassEffect(.clear.interactive(), in: Capsule())
        .scaleEffect(isScrubActive ? 0.6 : 1.0)
        .opacity(isScrubActive ? 0 : 1)
    }

    private func utilityIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Image(systemName: systemName)
            .font(.system(size: isPad ? 18 : 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: isPad ? 28 : 24, height: isPad ? 28 : 24)
            .opacity(isScrubActive ? 0 : 1)
            .padding(.horizontal, isPad ? 14 : 12)
            .padding(.vertical, isPad ? 10 : 8)
            .contentShape(Rectangle())
            .onTapGesture { action() }
            .accessibilityAddTraits(.isButton)
    }

    private var volumePill: some View {
        HStack(spacing: 10) {
            Text("\(Int(viewModel.systemVolume * 100))%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
                .opacity(isScrubActive ? 0 : 1)

            volumeScrubber
                .frame(width: isPad ? 110 : 70)
                .opacity(isScrubActive ? 0 : 1)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .opacity(isScrubActive ? 0 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.clear.interactive(), in: Capsule())
        .scaleEffect(isScrubActive ? 0.6 : 1.0)
        .opacity(isScrubActive ? 0 : 1)
    }

    // MARK: - Playback (center)

    private var playbackButtons: some View {
        HStack(spacing: isPad ? 56 : (isCompactHeight ? 36 : 48)) {
            glassPlaybackButton(systemName: "backward.fill", size: isPad ? 26 : 22) {
                viewModel.seekBackward(15)
            }

            glassPlaybackButton(systemName: playPauseIcon, size: isPad ? 40 : 32) {
                viewModel.togglePlayPause()
            }

            glassPlaybackButton(systemName: "forward.fill", size: isPad ? 26 : 22) {
                viewModel.seekForward(15)
            }
        }
    }

    private func glassPlaybackButton(systemName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size + 24, height: size + 24)
            .opacity(isScrubActive ? 0 : 1)
            .padding(.horizontal, isPad ? 16 : 12)
            .padding(.vertical, isPad ? 14 : 10)
            .contentShape(Capsule())
            .glassEffect(.clear.interactive(), in: Capsule())
            .scaleEffect(isScrubActive ? 0.6 : 1.0)
            .opacity(isScrubActive ? 0 : 1)
            .onTapGesture { action() }
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        // `.fixedSize(horizontal: true)` makes the VStack hug its
        // intrinsic width (= the HStack: digit + 10 + bar + 10 +
        // digit). Then `.frame(maxWidth: .infinity, alignment: .center)`
        // places the fixed-width VStack centered on screen. Without
        // the `.fixedSize`, the VStack would expand to the proposed
        // (full-screen) width and the inner `alignment: .leading`
        // would push the HStack to the screen's left edge.
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.videoTitle.isEmpty {
                Text(viewModel.videoTitle)
                    // HIG: semantic text style so Dynamic Type +
                    // accessibility sizes scale the title automatically.
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .allowsHitTesting(false)
                    .opacity(isScrubActive ? 0 : 1)
            }

            progressRow
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, isCompactHeight ? 20 : 32)
        .safeAreaPadding(.bottom)
    }

    /// Width of the progress bar itself. On landscape phones (where
    /// there's letterbox space outside the 16:9 video) the bar maps
    /// exactly to the 16:9 video edges, with the time digits sitting
    /// in the black letterbox area. On portrait / iPad layouts (video
    /// fills the screen, no letterbox), the bar yields room for the
    /// digits and a minimum side inset.
    private var progressBarWidth: CGFloat {
        guard screenSize.width > 0, screenSize.height > 0 else {
            return 0
        }
        let videoWidth = min(screenSize.width, screenSize.height * (16.0 / 9.0))
        let minSideInset: CGFloat = isPad ? 32 : 20
        // Landscape phone: letterbox to the sides of a 16:9 video has
        // plenty of room for digits, so the bar can match the full
        // video width without crowding.
        if videoWidth + 2 * minSideInset < screenSize.width {
            return videoWidth
        }
        // No letterbox room: reserve worst-case `H:MM:SS` digit width
        // plus a 10pt gap on each side.
        let digitReserve: CGFloat = 56 + 10
        return max(0, screenSize.width - 2 * (minSideInset + digitReserve))
    }

    private var progressRow: some View {
        // Time labels use intrinsic widths so the HStack's flex sizing
        // gives `progressScrubber` whatever space is left — the bar
        // compresses naturally when either digit string widens from
        // `M:SS` to `H:MM:SS`. The 10-pt HStack spacing is the only
        // gap between digits and bar, so left/right gaps stay
        // identical regardless of digit width. Active-state scale is
        // anchored *outward* (.trailing on start, .leading on end) so
        // the digits grow away from the bar — the bar's rendered
        // width does not change during scrub.
        let hasDuration = viewModel.duration > 0
        return HStack(spacing: 10) {
            Text(formatTime(viewModel.currentTime, placeholder: !hasDuration))
                .font(.system(size: Self.timeLabelBaseSize).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(isScrubActive ? 0.35 : 0), radius: 3, x: 0, y: 1)
                .scaleEffect(timeLabelScale, anchor: .trailing)
                .allowsHitTesting(false)

            progressScrubber
                .frame(width: progressBarWidth)

            Text(formatTime(viewModel.duration, placeholder: !hasDuration))
                .font(.system(size: Self.timeLabelBaseSize).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(isScrubActive ? 0.35 : 0), radius: 3, x: 0, y: 1)
                .scaleEffect(timeLabelScale, anchor: .leading)
                .allowsHitTesting(false)
        }
    }

    private var progressScrubber: some View {
        let duration = max(viewModel.duration, 1)
        let progress = viewModel.currentTime / duration
        let barHeight: CGFloat = isScrubbing ? 10 : 6
        return GeometryReader { geo in
            VStack {
                Spacer()
                // HIG: subtle drop shadow keeps the bar legible against
                // bright frames once the vignette fades on scrub. Cast
                // by the outer track capsule only; the fill sits as an
                // overlay so it never contributes a second shadow pass
                // (compositingGroup wasn't enough — different alphas in
                // the flattened layer still produced visible banding at
                // the fill edge). Opacity tied to scrub state — fades
                // in via the root `.animation(value:)`.
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(height: barHeight)
                    .shadow(color: .black.opacity(isScrubActive ? 0.35 : 0), radius: 3, x: 0, y: 1)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * progress, height: barHeight)
                    }
                Spacer()
            }
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: isScrubbing)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($isScrubbing) { _, state, _ in state = true }
                    .onChanged { value in
                        guard let startTime = dragStartTime, let lastX = lastDragX else {
                            inertiaTask?.cancel()
                            isFlinging = false
                            dragStartTime = viewModel.currentTime
                            lastDragX = value.location.x
                            accumulatedSeek = 0
                            lastZone = scrubZone(forY: value.location.y)
                            return
                        }
                        let dx = value.location.x - lastX
                        let zone = scrubZone(forY: value.location.y)
                        if let prev = lastZone, prev != zone {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        lastZone = zone
                        let speed = scrubSpeed(forZone: zone)
                        accumulatedSeek += (dx / geo.size.width) * duration * speed
                        lastDragX = value.location.x
                        viewModel.scrub(to: max(0, min(duration, startTime + accumulatedSeek)))
                    }
                    .onEnded { value in
                        let vx = Double(value.velocity.width)
                        guard abs(vx) > 300 else {
                            viewModel.seek(to: viewModel.currentTime)
                            clearScrubState()
                            return
                        }
                        let speed = scrubSpeed(forZone: scrubZone(forY: value.location.y))
                        let base = (dragStartTime ?? viewModel.currentTime) + accumulatedSeek
                        startInertia(velocity: vx, base: base, speed: speed, width: geo.size.width, duration: duration)
                    }
            )
        }
        .frame(height: 28)
        .onChange(of: isScrubActive) { _, active in
            viewModel.isInteractingWithControls = active
        }
    }

    private func scrubZone(forY y: CGFloat) -> Int {
        let h = screenSize.height > 0 ? screenSize.height : 1000
        if y < h / 2 { return 0 }
        if y < h * 3 / 4 { return 1 }
        return 2
    }

    private func scrubSpeed(forZone zone: Int) -> Double {
        switch zone {
        case 0: return 0.2
        case 1: return 0.5
        default: return 1.0
        }
    }

    private func clearScrubState() {
        dragStartTime = nil
        lastDragX = nil
        accumulatedSeek = 0
        isFlinging = false
        lastZone = nil
    }

    private func startInertia(velocity: Double, base: TimeInterval, speed: Double, width: CGFloat, duration: TimeInterval) {
        inertiaTask?.cancel()
        isFlinging = true
        let w = Double(width)
        inertiaTask = Task { @MainActor in
            var v = velocity
            var t = base
            let decayPerSec = 7.0
            var lastTick = Date()
            while abs(v) > 80 {
                if Task.isCancelled { return }
                let now = Date()
                let dt = min(max(now.timeIntervalSince(lastTick), 0.001), 0.05)
                lastTick = now
                let dx = v * dt
                let newT = max(0, min(duration, t + (dx / w) * duration * speed))
                if newT == t || newT == 0 || newT == duration {
                    t = newT
                    break
                }
                t = newT
                viewModel.scrub(to: t)
                v *= exp(-decayPerSec * dt)
                try? await Task.sleep(for: .milliseconds(16))
            }
            viewModel.seek(to: t)
            clearScrubState()
        }
    }

    private var volumeScrubber: some View {
        let barHeight: CGFloat = isVolumeScrubbing ? 12 : 6
        return GeometryReader { geo in
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(height: barHeight)
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * CGFloat(viewModel.systemVolume), height: barHeight)
                }
                Spacer()
            }
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: isVolumeScrubbing)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isVolumeScrubbing) { _, state, _ in state = true }
                    .onChanged { value in
                        let v = max(0, min(1, value.location.x / geo.size.width))
                        viewModel.systemVolume = Float(v)
                    }
            )
        }
        .frame(height: 28)
        .onChange(of: isVolumeScrubbing) { _, scrubbing in
            viewModel.isInteractingWithControls = scrubbing
        }
    }

    private var vignette: some View {
        Color.black.opacity(0.35)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private var playPauseIcon: String {
        viewModel.state == .playing ? "pause.fill" : "play.fill"
    }

    private func formatTime(_ seconds: TimeInterval, placeholder: Bool = false) -> String {
        if placeholder { return "--:--" }
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

struct VolumeViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> MediaPlayer.MPVolumeView {
        let view = MediaPlayer.MPVolumeView(frame: .zero)
        view.alpha = 0.001
        return view
    }
    func updateUIView(_ uiView: MediaPlayer.MPVolumeView, context: Context) {}
}

// MARK: - Previews

private func makePreviewVM() -> PlayerViewModel {
    let vm = PlayerViewModel()
    vm.videoTitle = "测试Inception.2010.4K.mkv"
    vm.currentTime = 3_723   // 1h 2m 3s
    vm.duration    = 8_940   // ~2h 29m
    vm.state       = .paused
    return vm
}

#Preview("iPhone Portrait") {
    ZStack {
        Color.black.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makePreviewVM())
}

#Preview("iPhone Landscape", traits: .landscapeLeft) {
    ZStack {
        Color.black.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makePreviewVM())
}

#Preview("iPad") {
    ZStack {
        Color.black.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makePreviewVM())
}

// MARK: - Overflow-stress previews (white background, HH:MM:SS)

/// Long-duration VM for testing how the outward-anchored time-label
/// scale behaves when both labels render `H:MM:SS` (7 chars) against a
/// bright frame. Drag the scrubber in the canvas to activate scrub
/// state and observe whether the magnified labels clip against the
/// safe-area edges or push past the bar.
private func makeLongDurationPreviewVM() -> PlayerViewModel {
    let vm = PlayerViewModel()
    vm.videoTitle = "Stress-Test.HH-MM-SS.mkv"
    vm.currentTime = 36_000          // 10:00:00 — widest plausible left label
    vm.duration    = 45_296          // 12:34:56 — widest plausible right label
    vm.state       = .paused
    return vm
}

#Preview("White BG · iPhone Portrait · HH:MM:SS") {
    ZStack {
        Color.white.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makeLongDurationPreviewVM())
}

#Preview("White BG · iPhone Landscape · HH:MM:SS", traits: .landscapeLeft) {
    ZStack {
        Color.white.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makeLongDurationPreviewVM())
}

#Preview("White BG · iPad · HH:MM:SS") {
    ZStack {
        Color.white.ignoresSafeArea()
        iOSPlayerControls()
    }
    .environment(makeLongDurationPreviewVM())
}
#endif
