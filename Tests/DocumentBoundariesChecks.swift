import Foundation

enum DocumentBoundariesChecks {
    static func run() async {
        await threeLettersSplitAtEachNewLetterhead(
            model: FixedAnswerModel(answer: PagePairQuestion.sameDocument), "with a model that says same document")
        await threeLettersSplitAtEachNewLetterhead(model: nil, "without Apple Intelligence")
        await numberedLetterStaysWholeDespiteChangingLetterheads()
        await blankPageSplitsWithoutAppleIntelligence()
        await pageOneAfterTheLastPageSplitsWithoutAppleIntelligence()
    }

    private static let words = try! PageCountWords.bundled()

    private static func splits(
        _ pages: [BoundaryPage], model: (any DocumentLanguageModel)?
    ) async -> [DocumentSplit] {
        await DocumentBoundaries.suggestedSplits(for: pages, words: words, model: model)
    }

    static func threeLettersSplitAtEachNewLetterhead(model: (any DocumentLanguageModel)?, _ setting: String) async {
        let pages = SampleLetterPages.threeLetters.map { BoundaryPage(text: $0) }
        let found = await splits(pages, model: model)
        expect(
            found == [DocumentSplit(pageIndex: 2, reason: .newLetterhead), DocumentSplit(pageIndex: 3, reason: .newLetterhead)],
            "three letters split at the first page of letters 2 and 3 \(setting)")
    }

    static func numberedLetterStaysWholeDespiteChangingLetterheads() async {
        let pages = SampleLetterPages.fourPageLetterWithChangingDates.map { BoundaryPage(text: $0) }
        let found = await splits(pages, model: FixedAnswerModel(answer: PagePairQuestion.newDocument))
        expect(
            found.isEmpty,
            "a letter numbered page 1 to 4 of 4 stays whole despite new letterheads and a new document model")
    }

    static func blankPageSplitsWithoutAppleIntelligence() async {
        let pages = [
            BoundaryPage(text: SampleLetterPages.followUp(["Vielen Dank für Ihre Bestellung vom letzten Monat."])),
            SampleLetterPages.blank,
            BoundaryPage(text: SampleLetterPages.followUp(["Ihre Kündigung haben wir erhalten und bestätigen sie."])),
        ]
        let found = await splits(pages, model: nil)
        expect(
            found == [DocumentSplit(pageIndex: 2, reason: .blankSeparator)],
            "without Apple Intelligence a blank page splits before the page after it")
    }

    static func pageOneAfterTheLastPageSplitsWithoutAppleIntelligence() async {
        let pages = [
            SampleLetterPages.followUp(["Ihre Rechnung für September."], footer: "Page 1 of 2"),
            SampleLetterPages.followUp(["Zahlbar innerhalb von 14 Tagen."], footer: "Page 2 of 2"),
            SampleLetterPages.followUp(["Ihre Rechnung für Oktober."], footer: "Page 1 of 2"),
            SampleLetterPages.followUp(["Zahlbar innerhalb von 14 Tagen ohne Abzug."], footer: "Page 2 of 2"),
        ].map { BoundaryPage(text: $0) }
        let found = await splits(pages, model: nil)
        expect(
            found == [DocumentSplit(pageIndex: 2, reason: .firstPageNumber)],
            "without Apple Intelligence page 1 of 2 after page 2 of 2 splits")
    }
}
