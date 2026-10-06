import Foundation

enum DocumentSplitsChecks {
    static func run() {
        suggestedSplitStartsADocumentOnlyWhenSuggestionsCount()
        confirmedSplitStartsADocumentInBothModes()
        splitOnTheFirstPageAddsNoEmptyDocument()
        removedSuggestionStaysRemovedAfterANewSuggestion()
        confirmingARemovedSplitBringsItBack()
        splitFollowsItsPageAfterAReorder()
    }

    private static let pages = (0..<5).map { _ in UUID() }

    private static func splits(suggestedAt index: Int, confirmedAt confirmed: Int) -> DocumentSplits {
        var splits = DocumentSplits()
        splits.suggest([pages[index]: .newLetterhead])
        splits.confirm(at: pages[confirmed])
        return splits
    }

    static func suggestedSplitStartsADocumentOnlyWhenSuggestionsCount() {
        let documents = splits(suggestedAt: 2, confirmedAt: 4)
        expect(
            documents.documents(of: pages) == [0..<2, 2..<4, 4..<5],
            "with suggestions a suggested and a confirmed split give three documents")
    }

    static func confirmedSplitStartsADocumentInBothModes() {
        let documents = splits(suggestedAt: 2, confirmedAt: 4)
        expect(
            documents.documents(of: pages, includingSuggested: false) == [0..<4, 4..<5],
            "without suggestions only the confirmed split divides the stack")
    }

    static func splitOnTheFirstPageAddsNoEmptyDocument() {
        var splits = DocumentSplits()
        splits.confirm(at: pages[0])
        expect(splits.documents(of: pages) == [0..<5], "a split on the first page adds no empty document")
    }

    static func removedSuggestionStaysRemovedAfterANewSuggestion() {
        var splits = DocumentSplits()
        splits.suggest([pages[2]: .newLetterhead])
        splits.remove(at: pages[2])
        splits.suggest([pages[2]: .newLetterhead])
        expect(splits.documents(of: pages) == [0..<5], "a removed suggestion stays removed after the next suggestion run")
    }

    static func confirmingARemovedSplitBringsItBack() {
        var splits = DocumentSplits()
        splits.suggest([pages[2]: .newLetterhead])
        splits.remove(at: pages[2])
        splits.confirm(at: pages[2])
        expect(
            splits.documents(of: pages, includingSuggested: false) == [0..<2, 2..<5],
            "confirming a removed split makes it a confirmed split")
    }

    static func splitFollowsItsPageAfterAReorder() {
        var splits = DocumentSplits()
        splits.suggest([pages[2]: .blankSeparator])
        let reordered = [pages[0], pages[3], pages[4], pages[2], pages[1]]
        expect(splits.documents(of: reordered) == [0..<3, 3..<5], "a split moves with its page when the stack is reordered")
    }
}
