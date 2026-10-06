public struct ScanRegion: Hashable, Sendable {
    public var leftMillimeters: Double
    public var topMillimeters: Double
    public var widthMillimeters: Double
    public var heightMillimeters: Double

    public init(
        leftMillimeters: Double = 0,
        topMillimeters: Double = 0,
        widthMillimeters: Double,
        heightMillimeters: Double
    ) {
        self.leftMillimeters = leftMillimeters
        self.topMillimeters = topMillimeters
        self.widthMillimeters = widthMillimeters
        self.heightMillimeters = heightMillimeters
    }

    public init(paper: PaperSize) {
        self.init(widthMillimeters: paper.widthMillimeters, heightMillimeters: paper.heightMillimeters)
    }

    public func clamped(to area: ScanArea) -> ScanRegion {
        let left = Self.limit(leftMillimeters, to: area.widthMillimeters)
        let top = Self.limit(topMillimeters, to: area.heightMillimeters)
        return ScanRegion(
            leftMillimeters: left,
            topMillimeters: top,
            widthMillimeters: Self.limit(widthMillimeters, to: area.widthMillimeters - left),
            heightMillimeters: Self.limit(heightMillimeters, to: area.heightMillimeters - top)
        )
    }

    private static func limit(_ value: Double, to upper: Double) -> Double {
        min(max(value, 0), upper)
    }
}
