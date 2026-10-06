public enum DocumentSplitState: Equatable, Sendable {
    case none
    case suggested(DocumentSplitReason)
    case confirmed
}
