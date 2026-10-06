import Foundation

extension ScanSession {
    private static let kindNames = (try? DocumentKindNames.bundled()) ?? DocumentKindNames(words: [:])

    // So that the export sheet, the grid, and a page dragged to Finder agree on names.
    func suggestedExportName(of document: Range<Int>) -> ExportFileName {
        ExportFileName(facts: facts(of: document), kindNames: Self.kindNames)
    }
}
