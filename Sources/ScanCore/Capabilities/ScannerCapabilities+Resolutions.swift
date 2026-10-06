extension ScannerCapabilities {
    // So that a scanner reporting a range still gets a short list of usual stops.
    static let commonResolutions = [75, 100, 150, 200, 300, 400, 600, 1200, 2400, 4800]

    public var resolutionChoices: [Int] {
        guard case .range(let lower, let upper, let step) = resolutionConstraint else {
            return resolutions
        }
        let stops = Self.commonResolutions.filter { stop in
            let value = Double(stop)
            guard value >= lower, value <= upper else { return false }
            guard let step, step > 0 else { return true }
            return (value - lower).truncatingRemainder(dividingBy: step) == 0
        }
        return stops.isEmpty ? [Int(lower.rounded()), Int(upper.rounded())] : stops
    }
}
