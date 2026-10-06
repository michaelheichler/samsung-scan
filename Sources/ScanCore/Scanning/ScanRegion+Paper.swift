extension ScanRegion {
    public func matches(_ paper: PaperSize, tolerance: Double = PaperCatalog.fitTolerance) -> Bool {
        abs(leftMillimeters) <= tolerance
            && abs(topMillimeters) <= tolerance
            && abs(widthMillimeters - paper.widthMillimeters) <= tolerance
            && abs(heightMillimeters - paper.heightMillimeters) <= tolerance
    }

    public func matchingPaper(in papers: [PaperSize]) -> PaperSize? {
        papers.first { matches($0) }
    }

    public func pixelSize(resolution: Int) -> (width: Int, height: Int) {
        let pixelsPerMillimeter = Double(resolution) / Inch.millimeters
        return (
            Int((widthMillimeters * pixelsPerMillimeter).rounded()),
            Int((heightMillimeters * pixelsPerMillimeter).rounded())
        )
    }
}
