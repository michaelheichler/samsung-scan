import CoreGraphics
import Foundation
import ImageIO

public enum BlankPageDetector {
    // So that 10 pt text on A4 keeps strokes of about one pixel.
    static let sampleLongSide = 600
    // Because scanner shadows and feeder edges sit in the outer 5 percent.
    static let edgeMarginFraction = 0.05
    // Because paper grain and JPEG noise stay within 10 of 255 levels.
    static let contentContrast = 26
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
        let inner = innerPixels(of: image)
        guard !inner.isEmpty else { return false }
        let paper = median(of: inner)
        let content = inner.count { abs(Int($0) - paper) > contentContrast }
        return Double(content) <= Double(inner.count) * maxContentFraction
    }

    private static func innerPixels(of image: CGImage) -> [UInt8] {
        let scale = min(1, Double(sampleLongSide) / Double(max(image.width, image.height)))
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let pixels = grayscale(image, width: width, height: height) else { return [] }
        let marginX = Int(Double(width) * edgeMarginFraction)
        let marginY = Int(Double(height) * edgeMarginFraction)
        guard width > 2 * marginX, height > 2 * marginY else { return [] }
        return (marginY..<(height - marginY)).flatMap { row in
            pixels[(row * width + marginX)..<(row * width + width - marginX)]
        }
    }

    private static func grayscale(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(bounds)
            context.interpolationQuality = .high
            context.draw(image, in: bounds)
            return true
        }
        return drawn ? pixels : nil
    }

    private static func median(of pixels: [UInt8]) -> Int {
        var histogram = [Int](repeating: 0, count: 256)
        for pixel in pixels {
            histogram[Int(pixel)] += 1
        }
        var seen = 0
        for (level, count) in histogram.enumerated() {
            seen += count
            if seen * 2 >= pixels.count { return level }
        }
        return 255
    }
}
