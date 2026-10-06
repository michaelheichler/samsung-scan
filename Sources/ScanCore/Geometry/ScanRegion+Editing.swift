extension ScanRegion {
    public var rightMillimeters: Double { leftMillimeters + widthMillimeters }
    public var bottomMillimeters: Double { topMillimeters + heightMillimeters }

    public func moved(dx: Double, dy: Double, within area: ScanArea) -> ScanRegion {
        let width = min(widthMillimeters, area.widthMillimeters)
        let height = min(heightMillimeters, area.heightMillimeters)
        return ScanRegion(
            leftMillimeters: Self.limit(leftMillimeters + dx, 0, area.widthMillimeters - width),
            topMillimeters: Self.limit(topMillimeters + dy, 0, area.heightMillimeters - height),
            widthMillimeters: width,
            heightMillimeters: height
        )
    }

    public func resized(
        _ handle: RegionHandle,
        dx: Double,
        dy: Double,
        within area: ScanArea,
        minimumSide: Double
    ) -> ScanRegion {
        let horizontal = Self.edges(
            leftMillimeters, rightMillimeters, by: dx, unit: handle.unitX,
            limit: area.widthMillimeters, minimumSide: minimumSide)
        let vertical = Self.edges(
            topMillimeters, bottomMillimeters, by: dy, unit: handle.unitY,
            limit: area.heightMillimeters, minimumSide: minimumSide)
        return ScanRegion(
            leftMillimeters: horizontal.low,
            topMillimeters: vertical.low,
            widthMillimeters: horizontal.high - horizontal.low,
            heightMillimeters: vertical.high - vertical.low
        )
    }

    public func isAtLeast(_ side: Double) -> Bool {
        widthMillimeters >= side && heightMillimeters >= side
    }

    // So that a handle stops at the opposite edge instead of flipping the region.
    private static func edges(
        _ low: Double,
        _ high: Double,
        by delta: Double,
        unit: Double,
        limit: Double,
        minimumSide: Double
    ) -> (low: Double, high: Double) {
        let side = min(minimumSide, limit)
        if unit == 0 {
            return (Self.limit(low + delta, 0, max(high - side, 0)), high)
        }
        if unit == 1 {
            return (low, Self.limit(high + delta, min(low + side, limit), limit))
        }
        return (low, high)
    }

    private static func limit(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), max(upper, lower))
    }
}
