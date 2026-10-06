import Foundation

public struct DocumentKindNames: Hashable, Sendable {
    public static let resourceFileName = "DocumentKindNames.json"
    public static let fallbackLanguage = "en"

    public let words: [String: [String: String]]

    public init(words: [String: [String: String]]) {
        self.words = words
    }

    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self.init(words: try JSONDecoder().decode([String: [String: String]].self, from: data))
    }

    public static func bundled() throws -> DocumentKindNames {
        try DocumentKindNames(contentsOf: PaperCatalog.locateResource(named: resourceFileName))
    }

    public func word(for kind: DocumentKind, language: Locale.LanguageCode?) -> String? {
        let table = language.flatMap { words[$0.identifier] }
        return table?[kind.rawValue] ?? words[Self.fallbackLanguage]?[kind.rawValue]
    }
}
