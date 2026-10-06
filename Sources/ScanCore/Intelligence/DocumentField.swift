public struct DocumentField: Equatable, Sendable {
    public let name: String
    public let guide: String
    // So that a decision field gets one of fixed answers, never free text.
    public let choices: [String]

    public init(name: String, guide: String, choices: [String] = []) {
        self.name = name
        self.guide = guide
        self.choices = choices
    }
}
