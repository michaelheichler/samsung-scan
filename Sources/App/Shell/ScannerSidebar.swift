import SwiftUI

struct ScannerSidebar: View {
    @Bindable var session: ScanSession

    private var showsEmptyState: Bool {
        session.devices.isEmpty && session.unlistedNetworkScanners.isEmpty && session.phase != .discovering
    }

    var body: some View {
        List(selection: $session.selectedDeviceName) {
            Section("Scanners") {
                ForEach(session.devices) { device in
                    ScannerRow(device: device)
                }
            }
            if !session.unlistedNetworkScanners.isEmpty {
                Section("Not Available") {
                    ForEach(session.unlistedNetworkScanners) { scanner in
                        NetworkScannerRow(scanner: scanner)
                            .selectionDisabled()
                    }
                }
            }
        }
        .disabled(session.phase.isBusy)
        .overlay {
            if showsEmptyState {
                ContentUnavailableView(
                    "No Scanners",
                    systemImage: "scanner",
                    description: Text("Turn on the scanner, connect it to this network, and refresh."))
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Refresh", systemImage: "arrow.clockwise", action: session.discoverScanners)
                    .disabled(session.phase.isBusy)
                    .help("Search for scanners again")
            }
        }
    }
}
