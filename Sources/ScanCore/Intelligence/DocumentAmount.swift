import Foundation

public struct DocumentAmount: Equatable, Sendable {
    public let value: Decimal
    public let currencyCode: String

    public init(value: Decimal, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode
    }
}
