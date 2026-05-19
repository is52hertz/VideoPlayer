import SwiftUI
import SwiftData

@main
struct VideoPlayerApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private var viewModel: PlayerViewModel { appDelegate.viewModel }
    #else
    @State private var viewModel = PlayerViewModel()
    @Environment(\.scenePhase) private var scenePhase
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

                OpenRotateDebugButton()
            }
        }

        Window("Rotate Speed Debug", id: "rotate-debug") {
            RotateSpeedDebugView()
        }
        .defaultSize(width: 720, height: 800)
        #else
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(viewModel)
                .onOpenURL { url in
                    viewModel.loadVideo(url: url)
                }
                .onChange(of: scenePhase) { _, phase in
                    // SwiftUI scenePhase 是 scene-based app 上最可靠的生命周期信号；
                    // 作为 SystemVolumeManager 内部 NotificationCenter 路径的双保险，
                    // 回 .active 时做高鲁棒性多次重读。
                    //
                    // 注意 (intentional)：这里**不**过滤 .inactive → .active 这种
                    // 短跳变（拉一半通知中心又收回、来电弹窗消失、App Switcher
                    // 切一下又回来 都会触发）。每次跑一次 resyncWithRetries 看
                    // 似浪费 (10 次 read / 1.2s)，但 read 是幂等的、代价可忽略，
                    // 而过滤掉这些短跳变意味着错过一些"短暂离开期间外部改了音量"
                    // 的边界场景。**不要轻易加 .background → .active 的过滤条件**。
                    if phase == .active {
                        SystemVolumeManager.shared.resyncWithRetries()
                    }
                }
        }
        .modelContainer(for: RecentVideo.self)
        #endif
    }
}

#if os(macOS)
/// 菜单项辅助：CommandGroup 内的 Button 拿不到 `@Environment(\.openWindow)`，
/// 必须包成 View 才能用。⌘⇧D 打开 Rotate Speed Debug 窗口。
private struct OpenRotateDebugButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("Rotate Speed Debug") {
            openWindow(id: "rotate-debug")
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
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
#endif
