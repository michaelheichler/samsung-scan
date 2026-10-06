import Foundation

extension ScanRequest {
    public static let optionYes = "yes"
    public static let optionNo = "no"

    // So that a German locale never sends "50,5" to scanimage.
    private static let optionNumberStyle = FloatingPointFormatStyle<Double>.number
        .locale(Locale(identifier: "en_US_POSIX"))
        .grouping(.never)
        .precision(.fractionLength(0...3))

    public static func optionText(_ number: Double) -> String {
        number.formatted(optionNumberStyle)
    }

    public func value(of option: ScannerOption) -> String? {
        extraOptionValues[option.name] ?? option.currentValue
    }

    public subscript(choice option: ScannerOption) -> String {
        get { value(of: option) ?? "" }
        set { extraOptionValues[option.name] = newValue }
    }

    public subscript(flag option: ScannerOption) -> Bool {
        get { value(of: option) == Self.optionYes }
        set { extraOptionValues[option.name] = newValue ? Self.optionYes : Self.optionNo }
    }

    public subscript(number option: ScannerOption) -> Double {
        get {
            if let number = value(of: option).flatMap(Double.init) { return number }
            if case .range(let lower, _, _) = option.value { return lower }
            return 0
        }
        set { extraOptionValues[option.name] = Self.optionText(newValue) }
    }
}
