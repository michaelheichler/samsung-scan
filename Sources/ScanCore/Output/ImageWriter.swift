import CoreGraphics
import Foundation
import ImageIO

enum ImageWriter {
    static func write(_ page: ScannedPage, as format: ExportFormat, quality: Double, to destination: URL) throws {
        let image = try visibleImage(of: page)
        guard
            let target = CGImageDestinationCreateWithURL(
                destination as CFURL, format.contentType.identifier as CFString, 1, nil)
        else {
            throw ImageWriterError.cannotCreateFile(fileName: destination.lastPathComponent)
        }
        CGImageDestinationAddImage(target, image, properties(of: page, format: format, quality: quality))
        guard CGImageDestinationFinalize(target) else {
            throw ImageWriterError.cannotCreateFile(fileName: destination.lastPathComponent)
        }
    }

    private static func visibleImage(of page: ScannedPage) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithURL(page.file as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
            let visible = image.cropping(to: page.visiblePixels(pixelWidth: image.width, pixelHeight: image.height))
        else {
            throw ImageWriterError.damagedPage(fileName: page.file.lastPathComponent)
        }
        return visible
    }

    private static func properties(of page: ScannedPage, format: ExportFormat, quality: Double) -> CFDictionary {
        var properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: page.resolution,
            kCGImagePropertyDPIHeight: page.resolution,
        ]
        if format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }
        return properties as CFDictionary
    }
}
