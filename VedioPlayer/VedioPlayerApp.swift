import SwiftUI
import SwiftData

@main
struct VedioPlayerApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var viewModel: PlayerViewModel { appDelegate.viewModel }
    #else
    @State private var viewModel = PlayerViewModel()
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(viewModel)
                .onOpenURL { url in
                    viewModel.loadVideo(url: url)
                }
        }
        .modelContainer(for: RecentVideo.self)
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Video...") {
                    viewModel.isShowingFilePicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
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
