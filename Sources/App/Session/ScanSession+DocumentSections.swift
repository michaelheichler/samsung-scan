import Foundation

extension ScanSession {
    var documentSections: [DocumentSection] {
        documents.enumerated().map { offset, range in
            let first = pages[range.lowerBound]
            return DocumentSection(
                number: offset + 1, pages: range, firstPage: first, name: suggestedExportName(of: range),
                split: offset == 0 ? .none : documentSplits.state(at: first.id))
        }
    }

    func document(containing page: ScannedPage) -> Range<Int>? {
        guard let index = pages.firstIndex(of: page) else { return nil }
        return documents.first { $0.contains(index) }
    }

    func splitState(of page: ScannedPage) -> DocumentSplitState {
        documentSplits.state(at: page.id)
    }

    func canSplit(at page: ScannedPage) -> Bool {
        pages.first != page && pages.contains(page)
    }
}
