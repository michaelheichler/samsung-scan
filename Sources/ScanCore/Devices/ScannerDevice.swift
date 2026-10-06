public struct ScannerDevice: Identifiable, Hashable, Sendable {
    public let name: String
    public let model: String

    public var id: String { name }
}
