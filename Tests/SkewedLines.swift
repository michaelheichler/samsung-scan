import CoreGraphics
import Foundation

// So that skew checks run without Vision, lines are built from a pixel angle.
enum SkewedLines {
    static func text(
        _ count: Int, atDegrees degrees: Double, widthFraction: Double = 0.6,
        pixelWidth: Int = A4Sheet.width, pixelHeight: Int = A4Sheet.height
    ) -> PageText {
        let lines = (0..<count).map { index in
            line(
                atDegrees: degrees, widthFraction: widthFraction, row: index,
                pixelWidth: Double(pixelWidth), pixelHeight: Double(pixelHeight))
        }
        return PageText(transcript: "", lines: lines)
    }

    private static func line(
        atDegrees degrees: Double, widthFraction: Double, row: Int, pixelWidth: Double, pixelHeight: Double
    ) -> RecognizedLine {
        let radians = degrees * .pi / 180
        let length = pixelWidth * widthFraction / cos(radians)
        let lineHeight = 30.0
        let start = CGPoint(x: pixelWidth * 0.1, y: pixelHeight * (0.85 - 0.06 * Double(row)))
        let end = CGPoint(x: start.x + length * cos(radians), y: start.y + length * sin(radians))
        let up = CGPoint(x: -sin(radians) * lineHeight, y: cos(radians) * lineHeight)
        func normalized(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x / pixelWidth, y: point.y / pixelHeight)
        }
        return RecognizedLine(
            text: "line \(row)",
            topLeft: normalized(CGPoint(x: start.x + up.x, y: start.y + up.y)),
            topRight: normalized(CGPoint(x: end.x + up.x, y: end.y + up.y)),
            bottomRight: normalized(end),
            bottomLeft: normalized(start))
    }
}
