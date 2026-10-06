import Foundation
import ImageIO

actor ThumbnailCache {
    private static let byteLimit = 256 * 1024 * 1024

    private let images = NSCache<NSString, CGImage>()
    private var formats: [ScannedPage.ID: PageFormat] = [:]

    init() {
        images.totalCostLimit = Self.byteLimit
    }

    func image(of page: ScannedPage, maxPixelSize: Int) -> CGImage? {
        let key = "\(page.id.uuidString)-\(maxPixelSize)" as NSString
        if let cached = images.object(forKey: key) { return cached }
        guard !Task.isCancelled, let source = Self.source(for: page) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        images.setObject(image, forKey: key, cost: image.bytesPerRow * image.height)
        return image
    }

    func format(of page: ScannedPage, catalog: PaperCatalog?) -> PageFormat? {
        if let cached = formats[page.id] { return cached }
        guard let source = Self.source(for: page),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let format = PageFormat(pixelWidth: width, pixelHeight: height, resolution: page.resolution, catalog: catalog)
        formats[page.id] = format
        return format
    }

    private static func source(for page: ScannedPage) -> CGImageSource? {
        CGImageSourceCreateWithURL(page.file as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary)
    }
}
