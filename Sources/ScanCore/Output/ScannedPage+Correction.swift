import CoreGraphics
import Foundation
import ImageIO

extension ScannedPage {
    // So that selection, order, and text stay attached, a corrected page keeps its ID.
    public func replacingFile(with file: URL, region: ScanRegion?) -> ScannedPage {
        ScannedPage(id: id, file: file, resolution: resolution, region: region)
    }

    // Because only the header is read, a menu can ask this without decoding the scan.
    public var pixelSize: (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(file as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }
}
