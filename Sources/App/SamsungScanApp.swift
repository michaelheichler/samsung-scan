import SwiftUI

@main
struct SamsungScanApp: App {
    static let windowID = "main"

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Samsung Scan", id: Self.windowID) {
            MainWindow(appDelegate: appDelegate)
        }
        .defaultSize(width: ShellView.defaultWidth, height: ShellView.defaultHeight)
        .windowResizability(.contentMinSize)
        .commands {
            DocumentCommands(session: appDelegate.session)
        }
    }
}
