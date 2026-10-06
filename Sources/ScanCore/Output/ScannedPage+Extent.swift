import CoreGraphics

extension ScannedPage {
    // Because the scanner returns a few more lines than the region holds (ISS-002).
    public func mediaBox(pixelWidth: Int, pixelHeight: Int) -> CGRect {
        guard let region else {
            let size = PDFWriter.pageSizeInPoints(pixelWidth: pixelWidth, pixelHeight: pixelHeight, resolution: resolution)
            return CGRect(origin: .zero, size: size)
        }
        let pointsPerMillimeter = Inch.points / Inch.millimeters
        return CGRect(
            x: 0, y: 0,
            width: region.widthMillimeters * pointsPerMillimeter,
            height: region.heightMillimeters * pointsPerMillimeter)
    }

    public func visiblePixels(pixelWidth: Int, pixelHeight: Int) -> CGRect {
        guard let region else { return CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight) }
        let requested = region.pixelSize(resolution: resolution)
        return CGRect(x: 0, y: 0, width: min(requested.width, pixelWidth), height: min(requested.height, pixelHeight))
    }
}
