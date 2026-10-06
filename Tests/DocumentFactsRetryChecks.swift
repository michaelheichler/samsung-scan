import Foundation
import Synchronization

@MainActor
enum DocumentFactsRetryChecks {
    static func run() async {
        await modelThatFailsTwiceFillsTheFactsOnTheThirdCall()
        await modelThatAlwaysFailsIsGivenUpAfterTheRetries()
        await modelThatTurnsOnLaterFillsTheFactsWhenAskedAgain()
        await answeredDocumentIsNotAskedAgain()
    }

    private static let quickRetries: [Duration] = [.milliseconds(5), .milliseconds(5)]

    static func modelThatFailsTwiceFillsTheFactsOnTheThirdCall() async {
        let model = FlakyModel(failing: 2, then: invoiceAnswer)
        let tracker = DocumentFactsTracker(model: { model }, retryDelays: quickRetries)
        tracker.update(firstPage: UUID(), text: invoice)
        let filled = await eventually { tracker.facts == invoiceFullFacts }
        expect(
            filled && model.callCount == 3,
            "a model that fails twice and then answers fills kind, title, and sender on the third call")
    }

    static func modelThatAlwaysFailsIsGivenUpAfterTheRetries() async {
        let model = FlakyModel(failing: .max, then: [:])
        let tracker = DocumentFactsTracker(model: { model }, retryDelays: quickRetries)
        tracker.update(firstPage: UUID(), text: invoice)
        _ = await eventually { model.callCount == quickRetries.count + 1 }
        try? await Task.sleep(for: .milliseconds(100))
        expect(
            model.callCount == quickRetries.count + 1 && tracker.facts == invoiceVisionFacts,
            "a model that always fails is asked once plus once per retry delay, and the vision facts stay")
    }

    static func modelThatTurnsOnLaterFillsTheFactsWhenAskedAgain() async {
        let model = FlakyModel(failing: 0, then: invoiceAnswer)
        let turnedOn = Mutex(false)
        let tracker = DocumentFactsTracker(
            model: { turnedOn.withLock { $0 } ? model : nil }, retryDelays: quickRetries)
        tracker.update(firstPage: UUID(), text: invoice)
        turnedOn.withLock { $0 = true }
        tracker.askAgainForMissingModelFacts()
        let filled = await eventually { tracker.facts == invoiceFullFacts }
        expect(filled, "a document scanned before Apple Intelligence was on gets its model facts when asked again")
    }

    static func answeredDocumentIsNotAskedAgain() async {
        let model = FlakyModel(failing: 0, then: invoiceAnswer)
        let tracker = DocumentFactsTracker(model: { model }, retryDelays: quickRetries)
        tracker.update(firstPage: UUID(), text: invoice)
        _ = await eventually { tracker.facts == invoiceFullFacts }
        tracker.askAgainForMissingModelFacts()
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            model.callCount == 1 && tracker.facts == invoiceFullFacts,
            "asking again for missing model facts leaves a document that already has its answer alone")
    }

    private static let invoiceDate = Date(timeIntervalSince1970: 1_773_486_000)
    private static let dueDate = Date(timeIntervalSince1970: 1_774_695_600)
    private static let net = DocumentAmount(value: Decimal(string: "109.16")!, currencyCode: "EUR")
    private static let total = DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR")

    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412\nNettobetrag: 109,16 EUR\nGesamtbetrag: 129,90 EUR\n"
            + "Bitte überweisen Sie den Betrag bis zum 28.03.2026.",
        lines: [], dates: [invoiceDate, dueDate], amounts: [net, total])

    private static let invoiceAnswer = ["kind": "invoice", "title": "Rechnung Nr. 2026-0412", "sender": "Musterfirma GmbH"]
    private static let invoiceVisionFacts = DocumentFacts(language: .german, date: invoiceDate, amount: total)
    private static let invoiceFullFacts = DocumentFacts(
        language: .german, kind: .invoice, title: "Rechnung Nr. 2026-0412", sender: "Musterfirma GmbH",
        date: invoiceDate, amount: total)

    private static func eventually(_ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}
