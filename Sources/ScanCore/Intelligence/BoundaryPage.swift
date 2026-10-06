public struct BoundaryPage: Equatable, Sendable {
    // So that a page whose text is still pending gives no cue at all.
    public let text: PageText?
    public let isBlank: Bool

    public init(text: PageText?, isBlank: Bool = false) {
        self.text = text
        self.isBlank = isBlank
    }
}
