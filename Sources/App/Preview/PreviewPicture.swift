import Foundation
import ImageIO

struct PreviewPicture: Sendable {
    let file: URL
    let image: CGImage
    let extent: ScanRegion?

    // So that the main actor never decodes the JPEG. The cache flag decodes now.
    @concurrent
    static func load(from file: URL) async -> PreviewPicture? {
        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, options)
        else { return nil }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let extent = (properties?[kCGImagePropertyDPIWidth] as? Double).map {
            ScanRegion(pixelWidth: image.width, pixelHeight: image.height, dotsPerInch: $0)
        }
        return PreviewPicture(file: file, image: image, extent: extent)
    }
}
