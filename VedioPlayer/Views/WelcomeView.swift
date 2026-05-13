import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit

struct WelcomeView: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Query(sort: \RecentVideo.lastOpened, order: .reverse) private var recentVideos: [RecentVideo]

    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "VedioPlayer"
    private let appVersion = "Version Preview"

    var body: some View {
        @Bindable var viewModel = viewModel
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Info and Actions (62%)
                ZStack {
                    VisualEffectBackground(material: .underWindowBackground)
                    Color.black.opacity(0.25) // Subtle lighter tint vs left pane

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        // App Icon area
                        WelcomeAppIcon()
                            .welcomeAppIconGlow()
                            .frame(width: 120, height: 120)
                            .padding(.bottom, 18)

                        Text(appName)
                            .font(.system(size: 28, weight: .bold))

                        Text(appVersion)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 32)

                        // Actions
                        VStack(spacing: 10) {
                            WelcomeActionButton(
                                icon: "folder",
                                title: "Open Finder...",
                                action: { viewModel.isShowingFilePicker = true }
                            )

                            WelcomeActionButton(
                                icon: "photo.on.rectangle",
                                title: "Open Photos...",
                                action: {
                                    // Placeholder
                                }
                            )

                            WelcomeActionButton(
                                icon: "gearshape",
                                title: "Settings...",
                                action: {
                                    // Placeholder
                                }
                            )
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width * 0.62)
                
                // Right Pane: Recent Files (38%)
                ZStack {
                    VisualEffectBackground(material: .underWindowBackground)
                    Color.white.opacity(0.08) // Subtle lighter tint vs left pane

                    VStack(alignment: .leading, spacing: 0) {
                        if recentVideos.isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("无最近使用的文稿")
                                        .font(.title3)
                                        .foregroundStyle(.tertiary)
                                    Spacer()
                                }
                                Spacer()
                            }
                        } else {
                            List {
                                ForEach(recentVideos) { video in
                                    RecentVideoRow(video: video) {
                                        viewModel.loadVideo(url: video.url)
                                    }
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .listStyle(.sidebar)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.38)
            }
            .environment(\.colorScheme, .dark)
        }
        .frame(width: 802, height: 470)
        .ignoresSafeArea()
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .windowVibrancy()
        // Enable file dropping on the welcome screen
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
        // Handle file picker result
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
        .onReceive(NotificationCenter.default.publisher(for: .init("VideoLoadedNotification"))) { _ in
            openWindow(id: "player")
            dismissWindow(id: "welcome")
        }
    }
}

private struct WelcomeActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
        }
        .buttonStyle(WelcomeActionButtonStyle())
    }
}

private struct RecentVideoRow: View {
    let video: RecentVideo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RecentVideoRowContent(video: video)
        }
        .buttonStyle(RecentVideoRowStyle())
    }
}

private struct RecentVideoRowContent: View {
    let video: RecentVideo
    @Environment(\.isHovered) private var isHovered

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .font(.title2)
                .foregroundStyle(isHovered ? .white : .blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .font(.headline)
                    .foregroundStyle(isHovered ? .white : .primary)
                    .lineLimit(1)
                
                Text(video.url.path)
                    .font(.caption)
                    .foregroundStyle(isHovered ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }
}
#endif
