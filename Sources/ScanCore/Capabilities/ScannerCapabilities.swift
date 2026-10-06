public struct ScannerCapabilities: Hashable, Sendable {
    public let sources: [String]
    public let modes: [String]
    public let resolutions: [Int]
    public let resolutionConstraint: ScannerOptionValue?
    public let defaultSource: String?
    public let defaultMode: String?
    public let scanArea: ScanArea?
    public let extraOptions: [ScannerOption]

    public init(options: [ScannerOption]) {
        func option(_ name: StandardOptionName) -> ScannerOption? {
            options.first { $0.name == name.rawValue }
        }
        sources = Self.strings(of: option(.source))
        modes = Self.strings(of: option(.mode))
        resolutions = Self.integers(of: option(.resolution))
        resolutionConstraint = option(.resolution)?.value
        defaultSource = option(.source)?.currentValue
        defaultMode = option(.mode)?.currentValue
        if let width = Self.maximumMillimeters(of: option(.width)),
           let height = Self.maximumMillimeters(of: option(.height)) {
            scanArea = ScanArea(widthMillimeters: width, heightMillimeters: height)
        } else {
            scanArea = nil
        }
        extraOptions = options.filter { StandardOptionName(rawValue: $0.name) == nil }
    }

    private static func strings(of option: ScannerOption?) -> [String] {
        guard case .strings(let values) = option?.value else { return [] }
        return values
    }

    private static func integers(of option: ScannerOption?) -> [Int] {
        guard case .numbers(let values) = option?.value else { return [] }
        return values.compactMap { Int(exactly: $0) }
    }

    private static func maximumMillimeters(of option: ScannerOption?) -> Double? {
        guard let option, option.unit == .millimeter,
              case .range(_, let max, _) = option.value
        else { return nil }
        return max
    }
}
