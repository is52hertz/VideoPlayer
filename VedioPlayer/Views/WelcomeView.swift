import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit

struct WelcomeView: View {
    @Environment(PlayerViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentVideo.lastOpened, order: .reverse) private var recentVideos: [RecentVideo]

    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "VedioPlayer"
    private let appVersion = "Version Preview"

    var body: some View {
        @Bindable var viewModel = viewModel
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Pane: Info and Actions (75%)
                ZStack(alignment: .topLeading) {
                    Color.black.opacity(0.4) // Left side darker tint

                    // Custom Close Button
                    Button(action: {
                        NSApplication.shared.keyWindow?.close()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray.opacity(0.8), .black.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .padding(16)

                    VStack(spacing: 0) {
                        Spacer()

                        // App Icon area
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.3, blue: 0.5), Color(red: 0.1, green: 0.15, blue: 0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 128, height: 128)
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                            
                            Image(systemName: "play.square.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.white)
                        }
                        .padding(.bottom, 24)

                        Text(appName)
                            .font(.system(size: 32, weight: .bold))
                        
                        Text(appVersion)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 48)

                        // Actions
                        VStack(spacing: 12) {
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
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width * 0.75)
                
                // Right Pane: Recent Files (25%)
                ZStack {
                    Color.white.opacity(0.05) // Right side lighter tint

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
                                    Button(action: {
                                        viewModel.loadVideo(url: video.url)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "doc.richtext.fill")
                                                .font(.title2)
                                                .foregroundStyle(.blue)
                                                .frame(width: 40, height: 40)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(video.title)
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                
                                                Text(video.url.path)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .listStyle(.sidebar)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.25)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .background(.ultraThinMaterial)
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
        // Hide standard window title bar
        .onAppear {
            if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true // Allow dragging by the background
            }
        }
    }
}

private struct WelcomeActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isHovered = false

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
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
#endif
