import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {
    @Environment(PlayerViewModel.self) private var viewModel
    #if os(macOS)
    @State private var controlOffset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    #endif
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        GeometryReader { geometry in
            ZStack {
                #if os(macOS)
                WindowTrackerView(isVisible: Binding(get: { viewModel.isControlsVisible }, set: { _ in }), onHover: { hovering in
                    viewModel.isHovering = hovering
                })
                .ignoresSafeArea()
                #endif

                #if os(iOS)
                Color.black.ignoresSafeArea()
                #endif

                VideoSurfaceView(engine: viewModel.engine)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        #if os(macOS)
                        viewModel.handleVideoTap()
                        #else
                        viewModel.handleVideoTapIOS()
                        #endif
                    }

                // Controls overlay — always in hierarchy, opacity fades
                controlsOverlay
                    #if os(macOS)
                    .offset(controlOffset)
                    #endif
                    .opacity(viewModel.isControlsVisible ? 1 : 0)
                    .allowsHitTesting(viewModel.isControlsVisible)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isControlsVisible)
            }
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear {
            isFocused = true
        }
        .onKeyPress(.space) {
            viewModel.togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            viewModel.seekBackward(10)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.seekForward(10)
            return .handled
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }

    @ViewBuilder
    private var controlsOverlay: some View {
        #if os(macOS)
        macOSControlsOverlay
        #else
        iOSPlayerControls()
        #endif
    }

    #if os(macOS)
    @ViewBuilder
    private var macOSControlsOverlay: some View {
        @Bindable var viewModel = viewModel
        VStack {
            Spacer()

            GlassPanel {
                VStack(spacing: 12) {
                    // Row 1: Volume, Playback, and Utility
                    HStack(spacing: 16) {
                        // Volume Section
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            GlassSlider(
                                value: $viewModel.volume,
                                range: 0...1
                            )
                            .frame(width: 80)
                        }

                        Spacer()

                        // Main Playback Controls
                        HStack(spacing: 24) {
                            Button { viewModel.seekBackward(15) } label: {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)

                            Button { viewModel.togglePlayPause() } label: {
                                Image(systemName: playPauseIcon)
                                    .font(.system(size: 32))
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)

                            Button { viewModel.seekForward(15) } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Utility Section
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

                    // Row 2: Progress
                    HStack(spacing: 10) {
                        Text(formatTime(viewModel.currentTime))
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(.secondary)

                        GlassSlider(
                            value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.seek(to: $0) }
                            ),
                            range: 0...max(viewModel.duration, 1)
                        )

                        Text(formatTime(viewModel.duration))
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(width: 500)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        controlOffset = CGSize(
                            width: dragStartOffset.width + gesture.translation.width,
                            height: dragStartOffset.height + gesture.translation.height
                        )
                    }
                    .onEnded { _ in
                        dragStartOffset = controlOffset
                    }
            )
            .padding(.bottom, 40)
        }
    }
    #endif

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
