public enum ScannerOptionValue: Hashable, Sendable {
    case strings([String])
    case numbers([Double])
    case range(min: Double, max: Double, step: Double?)
    case boolean
    case unconstrained(String)
}
