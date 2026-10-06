import CoreGraphics
import Foundation
import ImageIO

public enum BlankPageDetector {
    // So that 10 pt text on A4 keeps strokes of about one pixel.
    static let sampleLongSide = 600
    // Because scanner shadows and feeder edges sit in the outer 5 percent.
    static let edgeMarginFraction = 0.05
    // So that specks under 5 mm2 pass and one line of 8 pt text is content.
    static let maxContentFraction = 0.0002

    @concurrent
    public static func isBlank(fileAt file: URL) async throws -> Bool {
        try Task.checkCancellation()
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: sampleLongSide,
        ]
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return isBlank(image)
    }

    public static func isBlank(_ image: CGImage) -> Bool {
        guard let sample = GraySample(image, longSide: sampleLongSide) else { return false }
        let inner = innerPixels(of: sample)
        guard !inner.isEmpty else { return false }
        let paper = GraySample.median(of: inner)
        let content = inner.count { sample.isContent($0, paper: paper) }
        return Double(content) <= Double(inner.count) * maxContentFraction
    }

    private static func innerPixels(of sample: GraySample) -> [UInt8] {
        guard let inner = sample.innerBounds(marginFraction: edgeMarginFraction) else { return [] }
        return sample.rows(inner.rows, columns: inner.columns)
    }
}
