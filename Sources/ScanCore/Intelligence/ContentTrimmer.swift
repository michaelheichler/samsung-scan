import CoreGraphics
import Foundation

public enum ContentTrimmer {
    // So that a receipt with 6 pt print keeps its strokes in the sample.
    static let sampleLongSide = 1200
    static let marginMillimeters = 5.0
    // So that ink near the edge stays, only the feeder edge line is skipped.
    static let edgeMarginFraction = 0.01
    // So that a single dust speck does not widen the crop.
    static let minimumContentPerLine = 2
    // Because a crop that keeps almost everything is not worth a new page.
    static let minimumSavedFraction = 0.02

    @concurrent
    public static func trim(_ page: ScannedPage, into folder: URL) async throws -> URL? {
        try Task.checkCancellation()
        let scan = try CorrectedPageFile.image(at: page.file)
        // Because the trimmed page drops the region, overscan rows must go first.
        guard let image = scan.cropping(to: page.visiblePixels(pixelWidth: scan.width, pixelHeight: scan.height))
        else { return nil }
        let margin = Int((marginMillimeters / Inch.millimeters * Double(page.resolution)).rounded())
        guard let bounds = contentBounds(of: image, marginPixels: margin),
              let cropped = image.cropping(to: bounds) else { return nil }
        try Task.checkCancellation()
        return try CorrectedPageFile.write(cropped, resolution: page.resolution, into: folder)
    }

    // Because CGImage.cropping(to:) counts rows from the top, so does this rect.
    static func contentBounds(of image: CGImage, marginPixels: Int) -> CGRect? {
        guard let sample = GraySample(image, longSide: sampleLongSide),
              let content = contentBounds(in: sample) else { return nil }
        let scaleX = Double(image.width) / Double(sample.width)
        let scaleY = Double(image.height) / Double(sample.height)
        let scaled = CGRect(
            x: content.minX * scaleX, y: content.minY * scaleY,
            width: content.width * scaleX, height: content.height * scaleY)
        let full = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let bounds = scaled.insetBy(dx: -Double(marginPixels), dy: -Double(marginPixels)).intersection(full).integral
        let keepsAlmostAll = bounds.width >= full.width * (1 - minimumSavedFraction)
            && bounds.height >= full.height * (1 - minimumSavedFraction)
        return keepsAlmostAll ? nil : bounds
    }

    private static func contentBounds(in sample: GraySample) -> CGRect? {
        guard let inner = sample.innerBounds(marginFraction: edgeMarginFraction) else { return nil }
        let paper = GraySample.median(of: sample.rows(inner.rows, columns: inner.columns))
        func isContent(row: Int, column: Int) -> Bool {
            sample.isContent(sample.pixels[row * sample.width + column], paper: paper)
        }
        let rows = inner.rows.filter { row in
            inner.columns.count { isContent(row: row, column: $0) } >= minimumContentPerLine
        }
        let columns = inner.columns.filter { column in
            inner.rows.count { isContent(row: $0, column: column) } >= minimumContentPerLine
        }
        guard let top = rows.first, let bottom = rows.last, let left = columns.first, let right = columns.last
        else { return nil }
        return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
    }
}
