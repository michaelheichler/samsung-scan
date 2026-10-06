import CoreGraphics
import Foundation

public enum PDFWriter {
    public static func pageSizeInPoints(pixelWidth: Int, pixelHeight: Int, resolution: Int) -> CGSize {
        let pointsPerPixel = Inch.points / Double(resolution)
        return CGSize(width: Double(pixelWidth) * pointsPerPixel, height: Double(pixelHeight) * pointsPerPixel)
    }

    public static func write(_ pages: [ScannedPage], to destination: URL) throws {
        guard let context = CGContext(destination as CFURL, mediaBox: nil, nil) else {
            throw PDFWriterError.cannotCreateFile
        }
        defer { context.closePDF() }
        for page in pages {
            try Task.checkCancellation()
            guard let image = jpegPassthroughImage(page.file) else {
                throw PDFWriterError.damagedPage(fileName: page.file.lastPathComponent)
            }
            var box = page.mediaBox(pixelWidth: image.width, pixelHeight: image.height)
            context.beginPage(mediaBox: &box)
            context.draw(image, in: topAlignedFrame(of: image, resolution: page.resolution, in: box))
            context.endPage()
        }
    }

    // So that extra scanned lines fall below the page, not squeezed in.
    private static func topAlignedFrame(of image: CGImage, resolution: Int, in box: CGRect) -> CGRect {
        let size = pageSizeInPoints(pixelWidth: image.width, pixelHeight: image.height, resolution: resolution)
        return CGRect(x: 0, y: box.height - size.height, width: size.width, height: size.height)
    }

    private static func jpegPassthroughImage(_ file: URL) -> CGImage? {
        guard let provider = CGDataProvider(url: file as CFURL) else { return nil }
        return CGImage(
            jpegDataProviderSource: provider, decode: nil,
            shouldInterpolate: true, intent: .defaultIntent)
    }
}
