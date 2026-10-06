extension ScanRegion {
    // Because the scanner may return more lines than the requested area holds.
    public init(pixelWidth: Int, pixelHeight: Int, dotsPerInch: Double) {
        let millimetersPerPixel = dotsPerInch > 0 ? Inch.millimeters / dotsPerInch : 0
        self.init(
            widthMillimeters: Double(pixelWidth) * millimetersPerPixel,
            heightMillimeters: Double(pixelHeight) * millimetersPerPixel
        )
    }
}
