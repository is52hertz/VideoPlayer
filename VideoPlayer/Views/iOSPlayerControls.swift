#if os(iOS)
import SwiftUI

struct iOSPlayerControls: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // UIDevice is authoritative — horizontalSizeClass is .regular on iPhone Pro Max landscape
    private var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    // iPhone landscape: vertical size class is compact regardless of model
    private var isLandscape: Bool { verticalSizeClass == .compact }

    @State private var isScrubbing = false

    var body: some View {
        if isPhone {
            iPhoneOverlay
        } else {
            iPadOverlay
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
                            .padding(.horizontal, 20)
                    }
                    
                    progressRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, isLandscape ? 8 : 16)
                        .safeAreaPadding(.bottom)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 12) {
            // Close button (Compact iOS-specific)
            GlassPanel {
                Button {
                    viewModel.closeVideo()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }

            // Utilities Pill
            GlassPanel {
                HStack(spacing: 16) {
                    Button {
                        // Future: handle resize
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .frame(height: 20)
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Future: handle PiP
                    } label: {
                        Image(systemName: "pip.enter")
                            .font(.system(size: 14, weight: .medium))
                            .frame(height: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Spacer()

            // Volume Pill
            GlassPanel {
                HStack(spacing: 10) {
                    Text("\(Int(viewModel.volume * 100))%")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(.secondary)

                    GlassSlider(value: $viewModel.volume, range: 0...1)
                        .frame(width: 70)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - iPad: GlassPanel (single glass layer, plain buttons inside)

    private var iPadOverlay: some View {
        @Bindable var viewModel = viewModel
        return VStack {
            Spacer()
            GlassPanel {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Volume
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            GlassSlider(value: $viewModel.volume, range: 0...1)
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
#endif
