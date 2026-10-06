import Foundation

@MainActor
enum DocumentFactsPerDocumentChecks {
    static func run() async {
        await eachDocumentStartGetsItsOwnVisionFacts()
        await droppingAStartDropsItsFacts()
        await droppingAStartDropsItsLateModelAnswer()
    }

    private static let invoiceDate = Date(timeIntervalSince1970: 1_773_486_000)
    private static let letterDate = Date(timeIntervalSince1970: 1_791_284_400)
    private static let total = DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR")

    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412\nGesamtbetrag: 129,90 EUR\nBitte überweisen Sie den Betrag bis Monatsende.",
        lines: [], dates: [invoiceDate], amounts: [total])
    private static let letter = PageText(
        transcript: "Dear Mr Smith,\nthank you for your letter. We have reviewed your request and will reply soon.",
        lines: [], dates: [letterDate])

    private static let invoiceFacts = DocumentFacts(language: .german, date: invoiceDate, amount: total)
    private static let letterFacts = DocumentFacts(language: .english, date: letterDate)

    static func eachDocumentStartGetsItsOwnVisionFacts() async {
        let tracker = DocumentFactsTracker(model: { nil })
        let (a, b, c) = (UUID(), UUID(), UUID())
        tracker.update(documentStarts: [a, c], texts: [a: invoice, b: letter, c: letter])
        expect(
            tracker.facts(ofDocumentStartingAt: a) == invoiceFacts && tracker.facts(ofDocumentStartingAt: c) == letterFacts,
            "each document start gets the vision facts of its own first page")
    }

    static func droppingAStartDropsItsFacts() async {
        let tracker = DocumentFactsTracker(model: { nil })
        let (a, c) = (UUID(), UUID())
        tracker.update(documentStarts: [a, c], texts: [a: invoice, c: letter])
        tracker.update(documentStarts: [a], texts: [a: invoice, c: letter])
        expect(
            tracker.facts(ofDocumentStartingAt: c) == .unknown && tracker.facts == invoiceFacts,
            "a page that no longer starts a document has no facts, the first document keeps its own")
    }

    static func droppingAStartDropsItsLateModelAnswer() async {
        let model = HeldAnswerModel()
        let tracker = DocumentFactsTracker(model: { model })
        let (a, c) = (UUID(), UUID())
        tracker.update(documentStarts: [a, c], texts: [a: invoice, c: letter])
        _ = await eventually { model.prompts.count == 2 }
        tracker.update(documentStarts: [a], texts: [a: invoice, c: letter])
        model.release(letter.transcript, with: "letter")
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            tracker.facts(ofDocumentStartingAt: c) == .unknown,
            "a late model answer for a dropped document start is dropped")
        model.settle(with: "invoice")
    }

    private static func eventually(_ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}
