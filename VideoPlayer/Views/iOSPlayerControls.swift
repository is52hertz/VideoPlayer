#if os(iOS)
import SwiftUI
import MediaPlayer

struct iOSPlayerControls: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    @State private var isScrubbing = false
    @State private var isVolumeScrubbing = false

    var body: some View {
        ZStack {
            // MPVolumeView must stay in hierarchy at all times for hardware buttons to work.
            VolumeViewWrapper()
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .accessibilityHidden(true)

            vignette

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
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isPad ? 18 : 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isPad ? 28 : 24, height: isPad ? 28 : 24)
                .padding(.horizontal, isPad ? 14 : 12)
                .padding(.vertical, isPad ? 10 : 8)
                .glassEffect(.clear.interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var utilityPill: some View {
        HStack(spacing: isPad ? 18 : 14) {
            utilityIconButton(systemName: "arrow.up.left.and.arrow.down.right") {
                // Future: handle resize
            }
            utilityIconButton(systemName: "pip.enter") {
                // Future: handle PiP
            }
        }
        .padding(.horizontal, isPad ? 14 : 12)
        .padding(.vertical, isPad ? 10 : 8)
        .glassEffect(.clear.interactive(), in: Capsule())
    }

    private func utilityIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isPad ? 18 : 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isPad ? 28 : 24, height: isPad ? 28 : 24)
        }
        .buttonStyle(.plain)
    }

    private var volumePill: some View {
        HStack(spacing: 10) {
            Text("\(Int(viewModel.systemVolume * 100))%")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))

            volumeScrubber
                .frame(width: isPad ? 110 : 70)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.clear.interactive(), in: Capsule())
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
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size + 24, height: size + 24)
                .padding(.horizontal, isPad ? 16 : 12)
                .padding(.vertical, isPad ? 14 : 10)
                .glassEffect(.clear.interactive(), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.videoTitle.isEmpty {
                Text(viewModel.videoTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, isPad ? 56 : 40)
                    .safeAreaPadding(.horizontal)
                    .allowsHitTesting(false)
            }

            progressRow
                .padding(.horizontal, isPad ? 32 : 20)
                .safeAreaPadding(.horizontal)
                .padding(.bottom, isCompactHeight ? 8 : 16)
                .safeAreaPadding(.bottom)
        }
    }

    private var progressRow: some View {
        HStack(spacing: 10) {
            Text(formatTime(viewModel.currentTime))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(minWidth: 42, alignment: .trailing)
                .allowsHitTesting(false)

            progressScrubber

            Text(formatTime(viewModel.duration))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(minWidth: 42, alignment: .leading)
                .allowsHitTesting(false)
        }
    }

    private var progressScrubber: some View {
        let duration = max(viewModel.duration, 1)
        let progress = viewModel.currentTime / duration
        let barHeight: CGFloat = isScrubbing ? 12 : 6
        return GeometryReader { geo in
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(height: barHeight)
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * progress, height: barHeight)
                }
                Spacer()
            }
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.6), value: isScrubbing)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isScrubbing = true
                        let t = max(0, min(duration, (value.location.x / geo.size.width) * duration))
                        viewModel.seek(to: t)
                    }
                    .onEnded { _ in
                        isScrubbing = false
                    }
            )
        }
        .frame(height: 28)
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
                    .onChanged { value in
                        isVolumeScrubbing = true
                        let v = max(0, min(1, value.location.x / geo.size.width))
                        viewModel.systemVolume = Float(v)
                    }
                    .onEnded { _ in
                        isVolumeScrubbing = false
                    }
            )
        }
        .frame(height: 28)
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

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
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
#endif
