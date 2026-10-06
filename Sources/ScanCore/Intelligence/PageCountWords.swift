import Foundation

public struct PageCountWords: Sendable {
    public static let resourceFileName = "PageCountWords.json"

    private let pattern: NSRegularExpression?

    // So that one table entry reads {"page": [...], "of": [...]} per language.
    public init(languages: [String: [String: [String]]]) {
        let page = Self.alternatives(languages.values.flatMap { $0["page"] ?? [] })
        let of = Self.alternatives(languages.values.flatMap { $0["of"] ?? [] } + ["/"])
        pattern = page.isEmpty ? nil : try? NSRegularExpression(
            pattern: "(?<!\\p{L})(?:\(page))\\s*(\\d{1,3})\\s*(?:\(of))\\s*(\\d{1,3})(?!\\d)",
            options: [.caseInsensitive])
    }

    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self.init(languages: try JSONDecoder().decode([String: [String: [String]]].self, from: data))
    }

    public static func bundled() throws -> PageCountWords {
        try PageCountWords(contentsOf: PaperCatalog.locateResource(named: resourceFileName))
    }

    // So that a reference like "see page 12 of 3" never counts as a page footer.
    public func pageNumber(in transcript: String) -> PageNumber? {
        guard let pattern else { return nil }
        let range = NSRange(transcript.startIndex..., in: transcript)
        for match in pattern.matches(in: transcript, range: range) {
            guard let number = Int(text(of: match.range(at: 1), in: transcript)),
                  let total = Int(text(of: match.range(at: 2), in: transcript)),
                  number >= 1, number <= total else { continue }
            return PageNumber(number: number, total: total)
        }
        return nil
    }

    private func text(of range: NSRange, in transcript: String) -> String {
        Range(range, in: transcript).map { String(transcript[$0]) } ?? ""
    }

    // Because "p" would match inside "pagina", longer words must come first.
    private static func alternatives(_ words: [String]) -> String {
        Set(words.map { $0.lowercased() })
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
    }
}
