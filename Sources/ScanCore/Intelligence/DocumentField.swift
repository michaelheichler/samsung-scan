public struct DocumentField: Equatable, Sendable {
    public let name: String
    public let guide: String

    public init(name: String, guide: String) {
        self.name = name
        self.guide = guide
    }
}
