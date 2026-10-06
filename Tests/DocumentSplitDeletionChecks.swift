import Foundation

enum DocumentSplitDeletionChecks {
    static func run() {
        splitOnADeletedMiddlePageMovesToTheNextPage()
        splitThatReachesTheFirstPageDisappears()
        splitOnADeletedLastPageDisappears()
    }

    private static func confirmedSplit(at id: ScannedPage.ID) -> DocumentSplits {
        var splits = DocumentSplits()
        splits.confirm(at: id)
        return splits
    }

    static func splitOnADeletedMiddlePageMovesToTheNextPage() {
        let pages = (0..<5).map { _ in UUID() }
        var splits = confirmedSplit(at: pages[2])
        splits.deletePage(pages[2], from: pages)
        expect(
            splits.documents(of: [pages[0], pages[1], pages[3], pages[4]], includingSuggested: false) == [0..<2, 2..<4],
            "deleting a page that starts a confirmed document lets the next page start it")
    }

    static func splitThatReachesTheFirstPageDisappears() {
        let pages = (0..<4).map { _ in UUID() }
        var splits = confirmedSplit(at: pages[1])
        splits.deletePage(pages[0], from: pages)
        splits.deletePage(pages[1], from: Array(pages.dropFirst()))
        expect(
            splits.documents(of: [pages[3], pages[2]], includingSuggested: false) == [0..<2],
            "a confirmed split deleted as the first page leaves no split behind for a later reorder")
    }

    static func splitOnADeletedLastPageDisappears() {
        let pages = (0..<3).map { _ in UUID() }
        var splits = confirmedSplit(at: pages[2])
        splits.deletePage(pages[2], from: pages)
        expect(
            splits.documents(of: [pages[0], pages[1]], includingSuggested: false) == [0..<2],
            "deleting the last page with a confirmed split leaves the other pages in one document")
    }
}
