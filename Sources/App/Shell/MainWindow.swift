import SwiftUI

struct MainWindow: View {
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ShellView(session: appDelegate.session)
            .onAppear(perform: registerReopen)
    }

    // So that a Dock click with no window open brings the kept pages back.
    private func registerReopen() {
        appDelegate.reopenWindow = { [openWindow] in openWindow(id: SamsungScanApp.windowID) }
    }
}
