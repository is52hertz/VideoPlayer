import SwiftUI

@main
struct VedioPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appDelegate.viewModel)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Video...") {
                    appDelegate.viewModel.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

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
