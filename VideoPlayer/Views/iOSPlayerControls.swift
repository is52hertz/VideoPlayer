#if os(iOS)
import SwiftUI

struct iOSPlayerControls: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var isLandscapeCompact: Bool {
        horizontalSizeClass == .compact && verticalSizeClass == .compact
    }

    var body: some View {
        if isCompact {
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
                // Top placeholder area — future: close / subtitle / volume
                Color.clear
                    .frame(height: isLandscapeCompact ? 44 : 56)
                    .safeAreaPadding(.top)

                Spacer()

                // Center: playback buttons — vertically centered, no background
                playbackButtons(
                    spacing: isLandscapeCompact ? 36 : 48,
                    backForwardSize: isLandscapeCompact ? 22 : 26,
                    playSize: isLandscapeCompact ? 32 : 38
                )

                Spacer()

                // Bottom: progress scrubber — pinned to bottom edge
                progressRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, isLandscapeCompact ? 8 : 16)
                    .safeAreaPadding(.bottom)
            }
        }
        .ignoresSafeArea()
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
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(height: 3)
                Capsule()
                    .fill(.white)
                    .frame(width: geo.size.width * progress, height: 3)
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                    .offset(x: max(0, geo.size.width * progress - 6))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = max(0, min(duration, (value.location.x / geo.size.width) * duration))
                        viewModel.seek(to: t)
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
                .frame(height: isLandscapeCompact ? 140 : 180)
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
                .frame(height: isLandscapeCompact ? 160 : 220)
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
