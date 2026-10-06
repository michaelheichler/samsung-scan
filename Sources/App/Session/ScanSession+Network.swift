extension ScanSession {
    var unlistedNetworkScanners: [DiscoveredScanner] {
        listedNetworkScanners.filter { !$0.isListed(in: devices) }
    }

    func watchNetworkScanners(with browser: ScannerBrowser = ScannerBrowser()) {
        networkWatch.start(with: browser) { [weak self] in
            self?.networkScannersDidChange()
        }
    }

    // So that a Bonjour change never cancels a scan or a settings read.
    private func networkScannersDidChange() {
        if phase.isBusy && phase != .discovering {
            networkWatch.refreshPending = true
        } else {
            discoverScanners()
        }
    }
}
