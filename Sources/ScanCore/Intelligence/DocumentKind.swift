import Foundation

public enum DocumentKind: String, CaseIterable, Sendable {
    case invoice
    case receipt
    case letter
    case contract
    case form
    case other

    // So that "Invoice." or " invoice" from the model still counts as an invoice.
    public init?(answer: String) {
        let word = answer.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        self.init(rawValue: word.lowercased())
    }

    public var name: String {
        self == .other ? "Document" : rawValue.capitalized
    }
}
