public struct PagePairQuestion: Equatable, Hashable, Sendable {
    // So that one pair call stays short, each side keeps at most this many bytes.
    static let bytesPerSide = 700

    static let sameDocument = "same document"
    static let newDocument = "new document"

    // So that the wording favors neither answer, both cases get equal weight.
    static let field = DocumentField(
        name: "pageB",
        guide: "Decide how page B relates to page A. "
            + "Pick same document when page B carries on a sentence, a list, or a table from page A. "
            + "Pick new document when page B starts with a title, a document number, a letterhead, "
            + "or a salutation of its own.",
        choices: [sameDocument, newDocument])

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
        switch answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case Self.newDocument: return true
        case Self.sameDocument: return false
        default: return nil
        }
    }
}
