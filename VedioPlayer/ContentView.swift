import SwiftUI

struct ContentView: View {
    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        switch viewModel.state {
        case .idle:
            idleView
        case .loading:
            loadingView
        case .ready, .playing, .paused, .finished:
            PlayerView()
        case .error(let message):
            errorView(message)
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Open a Video File")
                .font(.title2)
            Text("Supported formats: MP4, MOV, M4V, MKV, AVI, and more")
                .font(.caption)
                .foregroundStyle(.tertiary)
            GlassButton(systemName: "folder", action: { viewModel.openFile() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)
            Text("Playback Error")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            GlassButton(systemName: "arrow.counterclockwise", action: { viewModel.state = .idle })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
