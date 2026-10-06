import CoreGraphics

// So that blank check and trim judge paper and ink the same way.
struct GraySample {
    // Because paper grain and JPEG noise stay within 10 of 255 levels.
    static let contentContrast = 26

    let width: Int
    let height: Int
    let pixels: [UInt8]

    init?(_ image: CGImage, longSide: Int) {
        let scale = min(1, Double(longSide) / Double(max(image.width, image.height)))
        width = max(1, Int((Double(image.width) * scale).rounded()))
        height = max(1, Int((Double(image.height) * scale).rounded()))
        guard let pixels = Self.grayscale(image, width: width, height: height) else { return nil }
        self.pixels = pixels
    }

    func innerBounds(marginFraction: Double) -> (rows: Range<Int>, columns: Range<Int>)? {
        let marginX = Int(Double(width) * marginFraction)
        let marginY = Int(Double(height) * marginFraction)
        guard width > 2 * marginX, height > 2 * marginY else { return nil }
        return (marginY..<(height - marginY), marginX..<(width - marginX))
    }

    func rows(_ rows: Range<Int>, columns: Range<Int>) -> [UInt8] {
        rows.flatMap { row in pixels[(row * width + columns.lowerBound)..<(row * width + columns.upperBound)] }
    }

    func isContent(_ pixel: UInt8, paper: Int) -> Bool {
        abs(Int(pixel) - paper) > Self.contentContrast
    }

    static func median(of pixels: [UInt8]) -> Int {
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
}
