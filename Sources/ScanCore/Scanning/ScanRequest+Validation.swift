extension ScanRequest {
    // Because SANE names the standard color mode "Color" for every backend.
    static let colorMode = "Color"

    public func validated(against capabilities: ScannerCapabilities) -> ScanRequest {
        var request = self
        request.source = Self.supported(source, in: capabilities.sources, fallback: capabilities.defaultSource)
        request.mode = Self.supported(mode, in: capabilities.modes, fallback: capabilities.defaultMode)
        if let nearest = Self.nearest(to: Double(resolution), in: capabilities.resolutionConstraint) {
            request.resolution = Int(nearest.rounded())
        }
        if let area = capabilities.scanArea {
            request.region = region.clamped(to: area)
        }
        let activeNames = Set(capabilities.extraOptions.filter { !$0.isInactive }.map(\.name))
        request.extraOptionValues = extraOptionValues.filter { activeNames.contains($0.key) }
        return request
    }

    public func preview(for capabilities: ScannerCapabilities) -> ScanRequest {
        var request = self
        if let lowest = Self.lowest(in: capabilities.resolutionConstraint) {
            request.resolution = Int(lowest.rounded())
        }
        if capabilities.modes.contains(Self.colorMode), mode != Self.colorMode {
            request.mode = Self.colorMode
            // Because the capabilities report which options are active for the old mode.
            request.extraOptionValues = [:]
        }
        if let area = capabilities.scanArea {
            request.region = ScanRegion(paper: .fullArea(area))
        }
        request.pageLimit = 1
        return request.validated(against: capabilities)
    }

    private static func supported(_ value: String, in values: [String], fallback: String?) -> String {
        if values.isEmpty || values.contains(value) {
            return value
        }
        if let fallback, values.contains(fallback) {
            return fallback
        }
        return values.first ?? value
    }

    private static func nearest(to value: Double, in constraint: ScannerOptionValue?) -> Double? {
        switch constraint {
        case .numbers(let values):
            values.min { (abs($0 - value), -$0) < (abs($1 - value), -$1) }
        case .range(let lower, let upper, let step):
            snap(value, lower: lower, upper: upper, step: step)
        default:
            nil
        }
    }

    private static func snap(_ value: Double, lower: Double, upper: Double, step: Double?) -> Double {
        let clamped = min(max(value, lower), upper)
        guard let step, step > 0 else { return clamped }
        let snapped = lower + ((clamped - lower) / step).rounded() * step
        return snapped > upper ? snapped - step : snapped
    }

    private static func lowest(in constraint: ScannerOptionValue?) -> Double? {
        switch constraint {
        case .numbers(let values): values.min()
        case .range(let lower, _, _): lower
        default: nil
        }
    }
}
