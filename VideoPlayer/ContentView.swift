import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ContentView: View {
    @Bindable var viewModel: PlayerViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecents: [RecentVideo]

    var body: some View {
        ZStack {
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
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: viewModel.videoTypes
        ) { result in
            switch result {
            case .success(let url):
                viewModel.loadVideo(url: url)
            case .failure(let error):
                print("Error picking file: \(error.localizedDescription)")
            }
        }
        .onChange(of: viewModel.videoURL) { _, newURL in
            guard let url = newURL else { return }
            saveRecentVideo(url: url, title: viewModel.videoTitle)
        }
    }

    private func saveRecentVideo(url: URL, title: String) {
        let existing = allRecents.first(where: { $0.url == url })
        if let existing {
            existing.lastOpened = Date()
            existing.title = title
        } else {
            let newRecent = RecentVideo(url: url, title: title)
            modelContext.insert(newRecent)
        }
        try? modelContext.save()
    }

    @ViewBuilder
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
            GlassButton(systemName: "folder", action: { viewModel.isShowingFilePicker = true })
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
