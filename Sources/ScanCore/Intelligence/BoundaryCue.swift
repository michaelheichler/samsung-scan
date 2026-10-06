public enum BoundaryCue: Equatable, Sendable {
    case split(DocumentSplitReason)
    case join
    // Because a missing or failed answer keeps the pages together.
    case ask(PagePairQuestion)
}
