import SwiftUI
import SwiftData

@main
struct VideoPlayerApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var viewModel: PlayerViewModel { appDelegate.viewModel }
    #else
    @State private var viewModel = PlayerViewModel()
    #endif

    var body: some Scene {
        #if os(macOS)
        Window("Welcome", id: "welcome") {
            WelcomeView()
                .environment(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .modelContainer(for: RecentVideo.self)

        Window("Video Player", id: "player") {
            ContentView(viewModel: viewModel)
                .environment(viewModel)
                .onReceive(NotificationCenter.default.publisher(for: .init("VideoLoadedNotification"))) { _ in
                    // Bring the player window to front when a video is loaded (e.g., from Finder or Welcome screen)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)
        .modelContainer(for: RecentVideo.self)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Video...") {
                    viewModel.isShowingFilePicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(viewModel)
                .onOpenURL { url in
                    viewModel.loadVideo(url: url)
                }
        }
        .modelContainer(for: RecentVideo.self)
        #endif
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = PlayerViewModel()

    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        viewModel.loadVideo(url: URL(fileURLWithPath: filename))
        return true
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        guard let first = filenames.first else { return }
        viewModel.loadVideo(url: URL(fileURLWithPath: first))
        application.reply(toOpenOrPrint: .success)
    }
}
#endif
