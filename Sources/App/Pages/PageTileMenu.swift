import SwiftUI

struct PageTileMenu: View {
    let page: ScannedPage
    let number: Int
    let session: ScanSession
    let open: (ScannedPage) -> Void

    private var deleteCount: Int {
        session.pageSelection.ids.contains(page.id) ? session.selectedPageIDs.count : 1
    }

    var body: some View {
        Button("Open", systemImage: "eye", action: openPage)
        Divider()
        Button("Straighten", systemImage: "rotate.right", action: straighten)
            .disabled(!session.canStraighten(page))
        Button("Trim to Content", systemImage: "crop", action: trim)
            .disabled(!session.canTrim(page))
        Button("Undo Changes", systemImage: "arrow.uturn.backward", action: undoChanges)
            .disabled(!session.canUndoChanges(page))
        Divider()
        Group {
            Button("Move Earlier", systemImage: "arrow.left", action: moveEarlier)
                .disabled(number == 1)
            Button("Move Later", systemImage: "arrow.right", action: moveLater)
                .disabled(number == session.pages.count)
            Divider()
            Button("Delete ^[\(deleteCount) Page](inflect: true)", systemImage: "trash", role: .destructive, action: delete)
        }
        .disabled(!session.canEditPages)
    }

    private func openPage() {
        open(page)
    }

    private func straighten() {
        session.straighten(page)
    }

    private func trim() {
        session.trimToContent(page)
    }

    private func undoChanges() {
        session.undoChanges(page)
    }

    private func moveEarlier() {
        session.move(page, by: -1)
    }

    private func moveLater() {
        session.move(page, by: 1)
    }

    private func delete() {
        session.delete(page)
    }
}
