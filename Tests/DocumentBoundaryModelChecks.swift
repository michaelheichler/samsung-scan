import Foundation

enum DocumentBoundaryModelChecks {
    static func run() async {
        await newDocumentAnswerSplitsPagesWithoutCues()
        await modelSeesTheTextNearestThePageBreak()
        await cuelessPagesJoinWithoutAClearAnswer(FixedAnswerModel(answer: nil), "a failing model")
        await cuelessPagesJoinWithoutAClearAnswer(FixedAnswerModel(answer: "maybe"), "an unclear answer")
        await cuelessPagesJoinWithoutAClearAnswer(FixedAnswerModel(answer: "yes"), "a free yes outside the choices")
        await disagreeingCuesFollowTheModel(
            FixedAnswerModel(answer: PagePairQuestion.sameDocument), [], "a same document answer joins")
        await disagreeingCuesFollowTheModel(
            FixedAnswerModel(answer: PagePairQuestion.newDocument),
            [DocumentSplit(pageIndex: 1, reason: .languageModel)], "a new document answer splits")
        await disagreeingCuesFollowTheModel(nil, [], "without Apple Intelligence they join")
    }

    private static let words = try! PageCountWords.bundled()

    private static let cuelessPair = [
        BoundaryPage(text: PageText(transcript: "Wir bestätigen den Eingang Ihrer Zahlung.", lines: [])),
        BoundaryPage(text: PageText(transcript: "Your parcel will arrive on Monday.", lines: [])),
    ]

    static func newDocumentAnswerSplitsPagesWithoutCues() async {
        let found = await DocumentBoundaries.suggestedSplits(
            for: cuelessPair, words: words, model: FixedAnswerModel(answer: PagePairQuestion.newDocument))
        expect(
            found == [DocumentSplit(pageIndex: 1, reason: .languageModel)],
            "a new document answer from the model splits two pages without cues")
    }

    static func modelSeesTheTextNearestThePageBreak() async {
        let filler = String(repeating: "Der Vertrag läuft unverändert weiter. ", count: 130)
        let pages = [
            BoundaryPage(text: PageText(transcript: "OPENING-OF-A " + filler + " CLOSING-OF-A", lines: [])),
            BoundaryPage(text: PageText(transcript: "OPENING-OF-B " + filler + " CLOSING-OF-B", lines: [])),
        ]
        let model = FixedAnswerModel(answer: PagePairQuestion.sameDocument)
        _ = await DocumentBoundaries.suggestedSplits(for: pages, words: words, model: model)
        let prompt = model.prompts.first ?? ""
        expect(
            model.prompts.count == 1 && prompt.contains("CLOSING-OF-A") && prompt.contains("OPENING-OF-B")
                && !prompt.contains("OPENING-OF-A") && !prompt.contains("CLOSING-OF-B"),
            "for two 5000 character pages the model sees only the end of A and the start of B")
    }

    static func cuelessPagesJoinWithoutAClearAnswer(_ model: FixedAnswerModel, _ answer: String) async {
        let found = await DocumentBoundaries.suggestedSplits(for: cuelessPair, words: words, model: model)
        expect(found.isEmpty && model.prompts.count == 1, "two pages without cues join after \(answer)")
    }

    static func disagreeingCuesFollowTheModel(
        _ model: FixedAnswerModel?, _ expected: [DocumentSplit], _ outcome: String
    ) async {
        let pages = [
            SampleLetterPages.letterhead(
                sender: "Stadtwerke Köln", street: "Ringstraße 12", town: "50667 Köln", date: "Köln, 12.03.2026",
                body: ["Sehr geehrte Frau Weber, wir passen Ihren Abschlag an."], footer: "Page 1 of 2"),
            SampleLetterPages.letterhead(
                sender: "Musterfirma GmbH", street: "Hauptstraße 5", town: "10115 Berlin", date: "Berlin, 6. Oktober 2026",
                body: ["Sehr geehrte Frau Weber, anbei Ihre Unterlagen."]),
        ].map { BoundaryPage(text: $0) }
        let found = await DocumentBoundaries.suggestedSplits(for: pages, words: words, model: model)
        expect(found == expected, "a new letterhead after page 1 of 2 asks the model and \(outcome)")
    }
}
