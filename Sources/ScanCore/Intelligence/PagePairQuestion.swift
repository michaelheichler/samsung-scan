public struct PagePairQuestion: Equatable, Hashable, Sendable {
    // So that one pair call stays short, each side keeps at most this many bytes.
    static let bytesPerSide = 700

    static let field = DocumentField(
        name: "newDocument",
        guide: "Answer yes or no. Answer yes only when page B opens a different document, "
            + "with a new salutation, a new letterhead, or a new subject line. "
            + "Answer no when page B goes on with the topic, the sentences, or the closing of page A.")

    public let endOfA: String
    public let startOfB: String

    public init(endOfA: String, startOfB: String) {
        self.endOfA = endOfA
        self.startOfB = startOfB
    }

    public init(between first: PageText, and second: PageText) async {
        // Because a byte-level tokenizer never needs more tokens than bytes.
        let bytes: (String) -> Int = { $0.utf8.count }
        let end = (try? await ModelInputCut.cut(
            String(first.transcript.reversed()), toTokens: Self.bytesPerSide, countingWith: bytes)) ?? ""
        let start = (try? await ModelInputCut.cut(
            second.transcript, toTokens: Self.bytesPerSide, countingWith: bytes)) ?? ""
        self.init(endOfA: String(end.reversed()), startOfB: start)
    }

    public var prompt: String {
        "End of page A:\n\(endOfA)\n\nStart of page B:\n\(startOfB)"
    }

    // Because a failed or unclear answer must fall back to the cues.
    public func startsNewDocument(using model: any DocumentLanguageModel) async -> Bool? {
        guard let answer = try? await model.fields([Self.field], from: prompt)[Self.field.name] else { return nil }
        let word = answer.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).lowercased()
        if word.hasPrefix("yes") || word == "true" { return true }
        if word.hasPrefix("no") || word == "false" { return false }
        return nil
    }
}
