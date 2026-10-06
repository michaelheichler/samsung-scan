import CoreGraphics
import Foundation

// Because paper edges vanish on this scanner (N-004), text lines give the angle.
public enum PageSkew {
    static let minimumLineWidthFraction = 0.2
    // Because fewer long lines make the median angle unreliable (N-004).
    static let minimumLineCount = 5
    static let minimumDegrees = 0.2

    public static func degrees(of text: PageText, pixelWidth: Int, pixelHeight: Int) -> Double? {
        let angles = text.lines.compactMap { angle(of: $0, width: Double(pixelWidth), height: Double(pixelHeight)) }
        guard angles.count >= minimumLineCount else { return nil }
        let sorted = angles.sorted()
        let middle = sorted.count / 2
        let median = sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        return abs(median) < minimumDegrees ? nil : median
    }

    private static func angle(of line: RecognizedLine, width: Double, height: Double) -> Double? {
        let dx = ((line.topRight.x + line.bottomRight.x) - (line.topLeft.x + line.bottomLeft.x)) / 2 * width
        let dy = ((line.topRight.y + line.bottomRight.y) - (line.topLeft.y + line.bottomLeft.y)) / 2 * height
        guard dx > width * minimumLineWidthFraction else { return nil }
        return atan2(dy, dx) * 180 / .pi
    }
}
