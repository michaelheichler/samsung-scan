import Foundation

extension ScanSession {
    private static let kindNames = (try? DocumentKindNames.bundled()) ?? DocumentKindNames(words: [:])

    // So that the export sheet and a page dragged to Finder suggest the same name.
    var suggestedExportName: ExportFileName {
        ExportFileName(facts: documentFacts, kindNames: Self.kindNames)
    }

    func suggestedExportName(of document: Range<Int>) -> ExportFileName {
        ExportFileName(facts: facts(of: document), kindNames: Self.kindNames)
    }
}
