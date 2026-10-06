import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum TestImage {
    static let a4Region = ScanRegion(widthMillimeters: 210, heightMillimeters: 297)

    static func jpeg(width: Int, height: Int, resolution: Int, in folder: URL, named name: String) -> URL {
        let url = folder.appending(path: name)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
        let properties = [kCGImagePropertyDPIWidth: resolution, kCGImagePropertyDPIHeight: resolution] as CFDictionary
        CGImageDestinationAddImage(destination, pattern(width: width, height: height), properties)
        CGImageDestinationFinalize(destination)
        return url
    }

    static func scannedA4Pages(_ count: Int, in folder: URL) -> [ScannedPage] {
        (1...count).map { number in
            let file = jpeg(width: 620, height: 891, resolution: 75, in: folder, named: "page00\(number).jpg")
            return ScannedPage(file: file, resolution: 75, region: a4Region)
        }
    }

    static func pixelSize(of file: URL) -> (width: Int, height: Int)? {
        properties(of: file).map { ($0[kCGImagePropertyPixelWidth] as? Int ?? 0, $0[kCGImagePropertyPixelHeight] as? Int ?? 0) }
    }

    static func resolution(of file: URL) -> Int? {
        (properties(of: file)?[kCGImagePropertyDPIWidth] as? NSNumber).map { Int($0.doubleValue.rounded()) }
    }

    private static func properties(of file: URL) -> [CFString: Any]? {
        CGImageSourceCreateWithURL(file as CFURL, nil)
            .flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
    }

    // So that JPEG quality changes the file size, the image needs detail.
    private static func pattern(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        for y in stride(from: 0, to: height, by: 6) {
            for x in stride(from: 0, to: width, by: 6) {
                let shade = Double((x * 7 + y * 13) % 256) / 255
                context.setFillColor(red: shade, green: 1 - shade, blue: Double(x % 256) / 255, alpha: 1)
                context.fill(CGRect(x: x, y: y, width: 6, height: 6))
            }
        }
        return context.makeImage()!
    }
}
