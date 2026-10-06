import Foundation
import NaturalLanguage

public enum DocumentFactReader {
    // So that a rambling model answer cannot flood the facts line or a file name.
    static let longestAnswer = 80

    static let kindField = DocumentField(
        name: "kind",
        guide: "The type of the document. Answer with one word: invoice, receipt, letter, contract, form, or other.")
    static let titleField = DocumentField(
        name: "title",
        guide: "A short title for the document in its own language, at most eight words.")
    static let senderField = DocumentField(
        name: "sender",
        guide: "The company or person who wrote or sent the document.")

    public static func visionFacts(from text: PageText) -> DocumentFacts {
        DocumentFacts(
            language: language(of: text.transcript),
            date: text.dates.first,
            amount: text.amounts.max { $0.value < $1.value })
    }

    public static func language(of transcript: String) -> Locale.LanguageCode? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(transcript)
        guard let language = recognizer.dominantLanguage, language != .undetermined else { return nil }
        return Locale.Language(identifier: language.rawValue).languageCode
    }

    // Because a failed or wrong model answer must never block scanning or export.
    public static func addingModelFacts(
        to facts: DocumentFacts, from text: PageText, using model: any DocumentLanguageModel
    ) async -> DocumentFacts {
        guard !text.transcript.isEmpty,
              let answer = try? await model.fields([kindField, titleField, senderField], from: text.transcript)
        else { return facts }
        var facts = facts
        facts.kind = answer[kindField.name].flatMap(DocumentKind.init(answer:))
        facts.title = cleaned(answer[titleField.name])
        facts.sender = cleaned(answer[senderField.name])
        return facts
    }

    private static func cleaned(_ answer: String?) -> String? {
        let text = answer?.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        guard let text, !text.isEmpty else { return nil }
        return String(text.prefix(longestAnswer))
    }
}
