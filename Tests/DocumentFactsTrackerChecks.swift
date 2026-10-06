import Foundation
import Synchronization

@MainActor
enum DocumentFactsTrackerChecks {
    static func run() async {
        await visionFactsShowAtOnceWithoutAppleIntelligence()
        await visionFactsShowWhileTheModelIsBusy()
        await modelFactsJoinWhenTheModelAnswers()
        await lateAnswerForAReplacedFirstPageIsDropped()
        await sameFirstPageAndTextAsksTheModelOnce()
        await removingTheTextGivesUnknownFactsAndDropsTheLateAnswer()
    }

    static func visionFactsShowAtOnceWithoutAppleIntelligence() async {
        let tracker = DocumentFactsTracker(model: { nil })
        tracker.update(firstPage: UUID(), text: invoice)
        expect(tracker.facts == invoiceVisionFacts, "without Apple Intelligence the facts hold only what Vision found")
    }

    static func visionFactsShowWhileTheModelIsBusy() async {
        let model = HeldModel()
        let tracker = DocumentFactsTracker(model: { model })
        tracker.update(firstPage: UUID(), text: invoice)
        let asked = await eventually { model.reached == [invoice.transcript] }
        expect(asked && tracker.facts == invoiceVisionFacts, "the vision facts show while the model is still busy")
        model.release(invoice.transcript, with: invoiceAnswer)
    }

    static func modelFactsJoinWhenTheModelAnswers() async {
        let model = HeldModel()
        let tracker = DocumentFactsTracker(model: { model })
        tracker.update(firstPage: UUID(), text: invoice)
        _ = await eventually { model.reached == [invoice.transcript] }
        model.release(invoice.transcript, with: invoiceAnswer)
        let joined = await eventually { tracker.facts == invoiceFullFacts }
        expect(joined, "the model answer adds kind, title, and sender to the vision facts")
    }

    static func lateAnswerForAReplacedFirstPageIsDropped() async {
        let model = HeldModel()
        let tracker = DocumentFactsTracker(model: { model })
        tracker.update(firstPage: UUID(), text: invoice)
        _ = await eventually { model.reached == [invoice.transcript] }
        tracker.update(firstPage: UUID(), text: letter)
        _ = await eventually { model.reached == [invoice.transcript, letter.transcript] }
        model.release(invoice.transcript, with: invoiceAnswer)
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            tracker.facts == letterVisionFacts,
            "after delete or reorder the late answer for the old first page is dropped")
        model.release(letter.transcript, with: [:])
    }

    static func sameFirstPageAndTextAsksTheModelOnce() async {
        let model = HeldModel()
        let tracker = DocumentFactsTracker(model: { model })
        let page = UUID()
        tracker.update(firstPage: page, text: invoice)
        _ = await eventually { model.reached == [invoice.transcript] }
        tracker.update(firstPage: page, text: invoice)
        model.release(invoice.transcript, with: invoiceAnswer)
        let joined = await eventually { tracker.facts == invoiceFullFacts }
        expect(
            joined && model.reached == [invoice.transcript],
            "the same first page and text twice asks the model once and keeps its answer")
    }

    static func removingTheTextGivesUnknownFactsAndDropsTheLateAnswer() async {
        let model = HeldModel()
        let tracker = DocumentFactsTracker(model: { model })
        tracker.update(firstPage: UUID(), text: invoice)
        _ = await eventually { model.reached == [invoice.transcript] }
        tracker.update(firstPage: nil, text: nil)
        model.release(invoice.transcript, with: invoiceAnswer)
        try? await Task.sleep(for: .milliseconds(50))
        expect(tracker.facts == .unknown, "a first page without text gives unknown facts even when a late answer arrives")
    }

    private static let invoiceDate = Date(timeIntervalSince1970: 1_773_486_000)
    private static let dueDate = Date(timeIntervalSince1970: 1_774_695_600)
    private static let letterDate = Date(timeIntervalSince1970: 1_791_284_400)
    private static let net = DocumentAmount(value: Decimal(string: "109.16")!, currencyCode: "EUR")
    private static let total = DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR")

    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412\nNettobetrag: 109,16 EUR\nGesamtbetrag: 129,90 EUR\n"
            + "Bitte überweisen Sie den Betrag bis zum 28.03.2026.",
        lines: [], dates: [invoiceDate, dueDate], amounts: [net, total])
    private static let letter = PageText(
        transcript: "Dear Mr Smith,\nthank you for your letter. We have reviewed your request and will reply soon.",
        lines: [], dates: [letterDate])

    private static let invoiceAnswer = ["kind": "invoice", "title": "Rechnung Nr. 2026-0412", "sender": "Musterfirma GmbH"]
    private static let invoiceVisionFacts = DocumentFacts(language: .german, date: invoiceDate, amount: total)
    private static let letterVisionFacts = DocumentFacts(language: .english, date: letterDate)
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

// So that a check decides when the model answers each transcript.
private final class HeldModel: DocumentLanguageModel {
    private struct Calls {
        var reached: [String] = []
        var held: [String: CheckedContinuation<[String: String], Never>] = [:]
    }

    private let calls = Mutex(Calls())

    var reached: [String] { calls.withLock { $0.reached } }

    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        await withCheckedContinuation { continuation in
            calls.withLock {
                $0.reached.append(text)
                $0.held[text] = continuation
            }
        }
    }

    func release(_ text: String, with answer: [String: String]) {
        calls.withLock { $0.held.removeValue(forKey: text) }?.resume(returning: answer)
    }
}
