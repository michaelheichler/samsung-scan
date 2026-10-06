public struct DocumentSplit: Equatable, Hashable, Sendable {
    public let pageIndex: Int
    public let reason: DocumentSplitReason

    public init(pageIndex: Int, reason: DocumentSplitReason) {
        self.pageIndex = pageIndex
        self.reason = reason
    }
}
