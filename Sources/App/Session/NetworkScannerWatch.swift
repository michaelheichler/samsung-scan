@MainActor
final class NetworkScannerWatch {
    private(set) var scanners: [DiscoveredScanner] = []
    var refreshPending = false
    private var task: Task<Void, Never>?

    func start(with browser: ScannerBrowser, onChange: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { [weak self] in
            for await scanners in browser.scanners() {
                self?.scanners = scanners
                onChange()
            }
        }
    }
}
