public struct ProcessResult: Sendable, Equatable {
    public let status: Int32
    public let output: String
    public let errors: String

    public init(status: Int32, output: String, errors: String) {
        self.status = status
        self.output = output
        self.errors = errors
    }
}
