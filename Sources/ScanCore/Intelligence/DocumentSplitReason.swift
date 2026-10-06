public enum DocumentSplitReason: String, Equatable, Hashable, Sendable {
    case firstPageNumber
    case blankSeparator
    case newLetterhead
    case languageModel

    public var summary: String {
        switch self {
        case .firstPageNumber: "The page says it is page 1"
        case .blankSeparator: "A blank page comes before it"
        case .newLetterhead: "A new sender and date start the page"
        case .languageModel: "Apple Intelligence reads a new document"
        }
    }
}
