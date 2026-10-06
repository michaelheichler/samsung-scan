import SwiftUI

struct DocumentTiles: View {
    let section: DocumentSection
    let pendingPageNumber: Int?
    let session: ScanSession
    let cache: ThumbnailCache
    let open: (ScannedPage) -> Void

    var body: some View {
        ForEach(session.pages[section.pages].enumerated(), id: \.element.id) { offset, page in
            PageTile(
                page: page, number: section.pages.lowerBound + offset + 1, document: section, session: session,
                cache: cache, open: open)
        }
        if let pendingPageNumber {
            PendingPageTile(number: pendingPageNumber, format: session.pendingPageFormat)
                .id(PageGrid.pendingTileID)
        }
    }
}
