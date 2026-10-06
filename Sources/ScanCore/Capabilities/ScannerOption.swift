public struct ScannerOption: Identifiable, Hashable, Sendable {
    public let name: String
    public let group: String
    public var description: String
    public let value: ScannerOptionValue
    public let unit: ScannerOptionUnit?
    public let currentValue: String?
    public let isInactive: Bool
    public let isAdvanced: Bool

    public var id: String { name }
}
