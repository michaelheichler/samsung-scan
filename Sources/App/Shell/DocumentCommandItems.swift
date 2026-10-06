import SwiftUI

// So that keyboard users split and join through the menu bar and its shortcuts.
struct DocumentCommandItems: View {
    let session: ScanSession

    private var selectedPage: ScannedPage? {
        let selected = session.selectedPages
        return selected.count == 1 ? selected.first : nil
    }

    var body: some View {
        DocumentSplitButtons(page: selectedPage, session: session)
    }
}
