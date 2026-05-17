#if os(iOS)
import SwiftUI
import MediaPlayer

struct iOSPlayerControls: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // UIDevice is authoritative — horizontalSizeClass is .regular on iPhone Pro Max landscape
    private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    // iPhone landscape: vertical size class is compact regardless of model
    private var isLandscape: Bool { verticalSizeClass == .compact }

    @State private var isScrubbing = false
    @State private var isVolumeScrubbing = false

    private enum Pill {
        static let hPad: CGFloat      = 12
        static let vPad: CGFloat      = 6
        static let contentH: CGFloat  = 28
        static let iconSize: CGFloat  = 14
        static let volTextSize: CGFloat = 12
        static let utilSpacing: CGFloat = 16
        static let volSpacing: CGFloat  = 10
        static let volSliderW: CGFloat  = 70
    }

    var body: some View {
        ZStack {
            // MPVolumeView must stay in hierarchy at all times for hardware buttons to work on both iPhone and iPad
            VolumeViewWrapper()
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .accessibilityHidden(true)

            if isPhone {
                iPhoneOverlay
            } else {
                iPadOverlay
            }
        }
    }

    // MARK: - iPhone: distributed overlay (Infuse-style)

    private var iPhoneOverlay: some View {
        ZStack {
            vignette

            VStack(spacing: 0) {
                // Top bar: close / utilities / volume
                topBar
                    .frame(height: isLandscape ? 44 : 56)
                    .safeAreaPadding(.top)

                Spacer()

                // Center: playback buttons — vertically centered, no background
                playbackButtons(
                    spacing: isLandscape ? 36 : 48,
                    backForwardSize: isLandscape ? 22 : 26,
                    playSize: isLandscape ? 32 : 38
                )

                Spacer()

                // Bottom: title and progress scrubber — pinned to bottom edge
                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.videoTitle.isEmpty {
                        Text(viewModel.videoTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .safeAreaPadding(.horizontal)
                    }

                    progressRow
                        .padding(.horizontal, 20)
                        .safeAreaPadding(.horizontal)
                        .padding(.bottom, isLandscape ? 8 : 16)
                        .safeAreaPadding(.bottom)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            // Close button (Compact iOS-specific)
            GlassPanel {
                Button {
                    viewModel.closeVideo()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: Pill.iconSize, weight: .bold))
                        .frame(width: Pill.contentH, height: Pill.contentH)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Pill.hPad)
                .padding(.vertical, Pill.vPad)
            }

            // Utilities Pill
            GlassPanel {
                HStack(spacing: Pill.utilSpacing) {
                    Button {
                        // Future: handle resize
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: Pill.iconSize, weight: .medium))
                            .frame(height: Pill.contentH)
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Future: handle PiP
                    } label: {
                        Image(systemName: "pip.enter")
                            .font(.system(size: Pill.iconSize, weight: .medium))
                            .frame(height: Pill.contentH)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Pill.hPad)
                .padding(.vertical, Pill.vPad)
            }

            Spacer()

            // Volume Pill
            GlassPanel {
                HStack(spacing: Pill.volSpacing) {
                    Text("\(Int(viewModel.systemVolume * 100))%")
                        .font(.system(size: Pill.volTextSize).monospacedDigit())
                        .foregroundStyle(.secondary)

                    volumeScrubber
                        .frame(width: Pill.volSliderW)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: Pill.volTextSize))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Pill.hPad)
                .padding(.vertical, Pill.vPad)
            }
        }
        .padding(.horizontal, 40)
        .safeAreaPadding(.horizontal)
    }

    // MARK: - iPad: GlassPanel (single glass layer, plain buttons inside)

    private var iPadOverlay: some View {
        VStack {
            Spacer()
            GlassPanel {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Volume
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            volumeScrubber
                                .frame(width: 100)
                        }

                        Spacer()

                        // Playback — plain buttons, no nested glass
                        HStack(spacing: 24) {
                            Button { viewModel.seekBackward(15) } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)

                            Button { viewModel.togglePlayPause() } label: {
                                Image(systemName: playPauseIcon)
                                    .font(.system(size: 32, weight: .medium))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)

                            Button { viewModel.seekForward(15) } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Utility placeholders
                        HStack(spacing: 16) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }

                    progressRow
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 16)
            .safeAreaPadding(.bottom)
        }
    }

    // MARK: - Shared subviews

    @ViewBuilder
    private func playbackButtons(spacing: CGFloat, backForwardSize: CGFloat, playSize: CGFloat) -> some View {
        HStack(spacing: spacing) {
            Button { viewModel.seekBackward(15) } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: backForwardSize, weight: .medium))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            Button { viewModel.togglePlayPause() } label: {
                Image(systemName: playPauseIcon)
                    .font(.system(size: playSize, weight: .medium))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)

            Button { viewModel.seekForward(15) } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: backForwardSize, weight: .medium))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
    }

    private var progressRow: some View {
        HStack(spacing: 10) {
            Text(formatTime(viewModel.currentTime))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(minWidth: 42, alignment: .trailing)

            progressScrubber

            Text(formatTime(viewModel.duration))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(minWidth: 42, alignment: .leading)
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
            .gesture(
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
            .gesture(
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
        ZStack {
            // Top darkening zone
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: isLandscape ? 140 : 180)
                Spacer()
            }
            // Bottom darkening zone
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: isLandscape ? 160 : 220)
            }
        }
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
#endif
