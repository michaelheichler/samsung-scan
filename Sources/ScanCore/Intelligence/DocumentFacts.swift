import Foundation

public struct DocumentFacts: Equatable, Sendable {
    public static let unknown = DocumentFacts()

    public var language: Locale.LanguageCode?
    public var kind: DocumentKind?
    public var title: String?
    public var sender: String?
    public var date: Date?
    public var amount: DocumentAmount?

    public init(
        language: Locale.LanguageCode? = nil,
        kind: DocumentKind? = nil,
        title: String? = nil,
        sender: String? = nil,
        date: Date? = nil,
        amount: DocumentAmount? = nil
    ) {
        self.language = language
        self.kind = kind
        self.title = title
        self.sender = sender
        self.date = date
        self.amount = amount
    }
}
