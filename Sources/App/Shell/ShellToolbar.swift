import SwiftUI

struct ShellToolbar: ToolbarContent {
    let session: ScanSession
    @Binding var showsInspector: Bool
    @Binding var isExporting: Bool
    @ViewState private var isConfirmingDiscard = false

    private var canUsePages: Bool {
        !session.pages.isEmpty && !session.phase.isBusy
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button("Preview", systemImage: "viewfinder", action: session.preview)
                .disabled(!session.canPreview)
                .help(session.previewHelp)
            if session.phase.isCancellable {
                Button("Cancel", systemImage: "stop.fill", action: session.cancel)
                    .keyboardShortcut(.cancelAction)
                    .help("Stop the scan")
            } else {
                Button("Scan", systemImage: "doc.viewfinder", action: session.scan)
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!session.canScan)
                    .help("Scan with the current settings")
            }
        }
        ToolbarItemGroup {
            Button("Export", systemImage: "square.and.arrow.up", action: showExport)
                .keyboardShortcut("e")
                .disabled(!canUsePages)
                .help("Export the scanned pages")
            Button("Delete Selected", systemImage: "trash", action: session.deleteSelectedPages)
                .disabled(!canUsePages || session.selectedPageIDs.isEmpty)
                .help("Delete the selected pages")
            Button("Discard All", systemImage: "xmark.bin", role: .destructive, action: confirmDiscard)
                .disabled(!canUsePages)
                .help("Remove all scanned pages")
                .confirmationDialog("Discard all scanned pages?", isPresented: $isConfirmingDiscard) {
                    Button("Discard All", role: .destructive, action: session.discardAllPages)
                }
        }
        ToolbarItem {
            Button("Scan Settings", systemImage: "sidebar.trailing", action: toggleInspector)
                .help(showsInspector ? "Hide scan settings" : "Show scan settings")
        }
    }

    private func showExport() {
        isExporting = true
    }

    private func confirmDiscard() {
        isConfirmingDiscard = true
    }

    private func toggleInspector() {
        showsInspector.toggle()
    }
}
