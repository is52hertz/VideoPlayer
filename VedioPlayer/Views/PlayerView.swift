import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {
    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            VideoSurfaceView(engine: viewModel.engine)
                .ignoresSafeArea()

            if viewModel.isControlsVisible {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .onHover { hovering in
            viewModel.isHovering = hovering
        }
        .onKeyPress { press in
            viewModel.handleKeyPress(press)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }

    @ViewBuilder
    private var controlsOverlay: some View {
        VStack {
            Spacer()

            GlassPanel {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Text(formatTime(viewModel.currentTime))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)

                        GlassSlider(
                            value: Binding(
                                get: { viewModel.duration > 0 ? viewModel.currentTime : 0 },
                                set: { viewModel.seek(to: $0) }
                            ),
                            range: 0...max(viewModel.duration, 1)
                        )

                        Text(formatTime(viewModel.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Spacer()
                        GlassButton(
                            systemName: playPauseIcon,
                            action: { viewModel.togglePlayPause() }
                        )
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    private var playPauseIcon: String {
        switch viewModel.state {
        case .playing:
            "pause.fill"
        default:
            "play.fill"
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
