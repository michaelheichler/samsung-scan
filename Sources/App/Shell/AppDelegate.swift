import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let session = ScanSession()
    var reopenWindow: (@MainActor () -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        session.watchNetworkScanners()
        session.discoverScanners()
    }

    // So that closing the window keeps unexported pages, as document apps do.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        session.pages.isEmpty
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag, let reopenWindow else { return true }
        reopenWindow()
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard confirmDiscardingPages() else { return .terminateCancel }
        guard session.phase.holdsScanner else { return .terminateNow }
        Task {
            await session.shutDown()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        session.workFolder.remove()
    }

    // Because quitting deletes the work folder with every unexported page.
    private func confirmDiscardingPages() -> Bool {
        let count = session.pages.count
        guard count > 0 else { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = count == 1 ? "Quit and discard 1 scanned page?" : "Quit and discard \(count) scanned pages?"
        alert.informativeText = "Pages you have not exported are deleted when Samsung Scan quits."
        // Because a habitual Return after Cmd-Q must never discard the pages.
        alert.addButton(withTitle: "Cancel").keyEquivalent = "\r"
        let quit = alert.addButton(withTitle: "Quit")
        quit.hasDestructiveAction = true
        quit.keyEquivalent = ""
        return alert.runModal() == .alertSecondButtonReturn
    }
}
