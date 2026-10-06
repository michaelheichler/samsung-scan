import Foundation

enum DocumentSplitStateChecks {
    static func run() {
        pageWithoutSplitReadsNone()
        suggestedSplitReadsItsReason()
        confirmedSplitReadsConfirmed()
        removedSuggestionReadsNone()
        confirmedSplitOverASuggestionReadsConfirmed()
    }

    private static let page = UUID()

    private static func suggestedSplits() -> DocumentSplits {
        var splits = DocumentSplits()
        splits.suggest([page: .blankSeparator])
        return splits
    }

    static func pageWithoutSplitReadsNone() {
        expect(DocumentSplits().state(at: page) == .none, "a page without a split reads as no split")
    }

    static func suggestedSplitReadsItsReason() {
        expect(
            suggestedSplits().state(at: page) == .suggested(.blankSeparator),
            "a suggested split reads as suggested with its reason")
    }

    static func confirmedSplitReadsConfirmed() {
        var splits = DocumentSplits()
        splits.confirm(at: page)
        expect(splits.state(at: page) == .confirmed, "a confirmed split reads as confirmed")
    }

    static func removedSuggestionReadsNone() {
        var splits = suggestedSplits()
        splits.remove(at: page)
        expect(splits.state(at: page) == .none, "a removed suggestion reads as no split")
    }

    static func confirmedSplitOverASuggestionReadsConfirmed() {
        var splits = suggestedSplits()
        splits.confirm(at: page)
        expect(splits.state(at: page) == .confirmed, "a confirmed split reads as confirmed even with a suggestion on its page")
    }
}
