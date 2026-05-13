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

    /// Tracks whether the cursor is anywhere over the welcome window content,
    /// so we can fade the custom close button in/out — matching the
    /// "controls appear only when needed" tenet in AGENTS.md.
    @State private var isWindowHovered = false

    private let appName: String = {
        let info = Bundle.main.infoDictionary
        return (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
            ?? "Video Player"
    }()
    private let appVersion = "Version Preview"

    var body: some View {
        @Bindable var viewModel = viewModel
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    // Left Pane: Info and Actions (62%)
                    ZStack {
                        VisualEffectBackground(material: .underWindowBackground)
                        Color.black.opacity(WelcomeLayout.leftPaneTintOpacity)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        // App Icon area
                        WelcomeAppIcon()
                            .welcomeAppIconGlow()
                            .padding(.bottom, WelcomeLayout.appIconBottomPadding)
                            .frame(width: WelcomeLayout.appIconFrameSize,
                                   height: WelcomeLayout.appIconFrameSize)

                        Text(appName)
                            .font(.system(size: WelcomeLayout.appNameFontSize, weight: .bold))

                        Text(appVersion)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, WelcomeLayout.versionBottomPadding)

                        // Actions
                        VStack(spacing: WelcomeLayout.actionButtonSpacing) {
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
                .frame(width: geometry.size.width * WelcomeLayout.leftPaneRatio)

                // Right Pane: Recent Files
                ZStack {
                    VisualEffectBackground(material: .underWindowBackground)
                    Color.white.opacity(WelcomeLayout.rightPaneTintOpacity) // Subtle lighter tint vs left pane

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
                .frame(width: geometry.size.width * WelcomeLayout.rightPaneRatio)
                }

                // Custom close button (Pixelmator Pro style).
                // Only revealed while the cursor is over the window; otherwise
                // it fades out so the welcome chrome stays calm.
                Button {
                    NSApplication.shared.keyWindow?.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: WelcomeLayout.closeButtonIconSize))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(WelcomeLayout.closeButtonPadding)
                .opacity(isWindowHovered ? 1 : 0)
                .allowsHitTesting(isWindowHovered)
                .animation(.easeInOut(duration: WelcomeLayout.closeButtonFadeDuration),
                           value: isWindowHovered)
            }
            .environment(\.colorScheme, .dark)
            .onHover { hovering in
                isWindowHovered = hovering
            }
        }
        .frame(width: WelcomeLayout.windowWidth, height: WelcomeLayout.windowHeight)
        .overlay(
            RoundedRectangle(cornerRadius: WelcomeLayout.windowCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(WelcomeLayout.windowBorderOpacity), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .windowVibrancy(contentSize: NSSize(width: WelcomeLayout.windowWidth,
                                            height: WelcomeLayout.windowHeight),
                        cornerRadius: WelcomeLayout.windowCornerRadius)
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
            HStack(spacing: WelcomeLayout.actionButtonIconSpacing) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: WelcomeLayout.actionButtonIconWidth)

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
        HStack(spacing: WelcomeLayout.recentRowContentSpacing) {
            VideoThumbnailView(
                url: video.url,
                size: WelcomeLayout.recentRowIconFrameSize,
                cornerRadius: WelcomeLayout.recentRowThumbnailCornerRadius,
                isHighlighted: isHovered
            )

            VStack(alignment: .leading, spacing: WelcomeLayout.recentRowTextSpacing) {
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
