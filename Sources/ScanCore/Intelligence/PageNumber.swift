public struct PageNumber: Equatable, Sendable {
    public let number: Int
    public let total: Int

    public init(number: Int, total: Int) {
        self.number = number
        self.total = total
    }

    public var startsDocument: Bool { number == 1 }
    public var continuesDocument: Bool { number > 1 }
    public var expectsMorePages: Bool { number < total }
}
