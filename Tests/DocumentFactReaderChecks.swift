import Foundation
import Synchronization

enum DocumentFactReaderChecks {
    static func run() async {
        kindAnswersIgnoreCaseSpacesAndPunctuation()
        await modelAnswersJoinTheVisionFacts()
        await throwingModelMakesTheReaderThrow()
        await unknownKindWordLeavesKindEmptyButKeepsTitleAndSender()
        await answersLoseSurroundingQuotesAndSpaces()
        await blankAnswersGiveNoFacts()
        await longAnswersAreCutAndKeepTheirStart()
        await emptyTranscriptNeverReachesTheModel()
    }

    static func kindAnswersIgnoreCaseSpacesAndPunctuation() {
        let answers = ["Invoice.", " receipt\n", "LETTER", "Contract!", "form", "Other", "banana", ""]
        expect(
            answers.map(DocumentKind.init(answer:)) == [.invoice, .receipt, .letter, .contract, .form, .other, nil, nil],
            "a kind answer counts regardless of case, spaces, and punctuation, and an unknown word is no kind")
    }

    static func modelAnswersJoinTheVisionFacts() async {
        let model = ScriptedModel(.success([
            "kind": "Invoice.", "title": "Rechnung Nr. 2026-0412", "sender": "Musterfirma GmbH",
        ]))
        let facts = try? await DocumentFactReader.addingModelFacts(to: visionFacts, from: invoice, using: model)
        let expected = DocumentFacts(
            language: .german, kind: .invoice, title: "Rechnung Nr. 2026-0412", sender: "Musterfirma GmbH",
            date: invoiceDate, amount: total)
        expect(
            facts == expected && model.transcripts == [invoice.transcript],
            "the model reads the page transcript once and adds kind, title, and sender to the vision facts")
    }

    static func throwingModelMakesTheReaderThrow() async {
        let model = ScriptedModel(.failure(CocoaError(.fileReadUnknown)))
        let error = await caughtError {
            _ = try await DocumentFactReader.addingModelFacts(to: visionFacts, from: invoice, using: model)
        }
        expect(
            (error as? CocoaError)?.code == .fileReadUnknown,
            "a model that throws makes adding model facts throw the same error, so the caller can retry")
    }

    static func unknownKindWordLeavesKindEmptyButKeepsTitleAndSender() async {
        let model = ScriptedModel(.success(["kind": "banana", "title": "Rechnung", "sender": "Musterfirma GmbH"]))
        let facts = try? await DocumentFactReader.addingModelFacts(to: .unknown, from: invoice, using: model)
        expect(
            facts == DocumentFacts(title: "Rechnung", sender: "Musterfirma GmbH"),
            "an unknown kind word gives no kind and keeps the title and sender answers")
    }

    static func answersLoseSurroundingQuotesAndSpaces() async {
        let model = ScriptedModel(.success(["title": " \"Rechnung\"\n", "sender": "  Musterfirma GmbH "]))
        let facts = try? await DocumentFactReader.addingModelFacts(to: .unknown, from: invoice, using: model)
        expect(
            facts?.title == "Rechnung" && facts?.sender == "Musterfirma GmbH",
            "title and sender answers lose surrounding quotes, spaces, and line breaks")
    }

    static func blankAnswersGiveNoFacts() async {
        let model = ScriptedModel(.success(["kind": " ", "title": "  \n", "sender": "\"\""]))
        let facts = try? await DocumentFactReader.addingModelFacts(to: visionFacts, from: invoice, using: model)
        expect(facts == visionFacts, "blank or empty quoted answers give no kind, title, or sender")
    }

    static func longAnswersAreCutAndKeepTheirStart() async {
        let long = String(repeating: "Musterfirma GmbH ", count: 12)
        let model = ScriptedModel(.success(["title": long, "sender": long]))
        let facts = try? await DocumentFactReader.addingModelFacts(to: .unknown, from: invoice, using: model)
        let cut = String(long.prefix(DocumentFactReader.longestAnswer))
        expect(
            long.count > DocumentFactReader.longestAnswer && facts?.title == cut && facts?.sender == cut,
            "a rambling title or sender answer is cut to the longest answer and keeps its start")
    }

    static func emptyTranscriptNeverReachesTheModel() async {
        let model = ScriptedModel(.success(["kind": "invoice"]))
        let empty = PageText(transcript: "", lines: [])
        let facts = try? await DocumentFactReader.addingModelFacts(to: .unknown, from: empty, using: model)
        expect(
            model.transcripts.isEmpty && facts == .unknown,
            "a page without text never asks the model and keeps the given facts")
    }

    private static let invoiceDate = Date(timeIntervalSince1970: 1_773_486_000)
    private static let total = DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR")
    private static let visionFacts = DocumentFacts(language: .german, date: invoiceDate, amount: total)
    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412\nGesamtbetrag: 129,90 EUR", lines: [], dates: [invoiceDate], amounts: [total])
}

// So that checks run without Apple Intelligence and see what the model was asked.
private final class ScriptedModel: DocumentLanguageModel {
    private let answer: Result<[String: String], any Error>
    private let asked = Mutex<[String]>([])

    init(_ answer: Result<[String: String], any Error>) {
        self.answer = answer
    }

    var transcripts: [String] { asked.withLock { $0 } }

    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        asked.withLock { $0.append(text) }
        return try answer.get()
    }
}
