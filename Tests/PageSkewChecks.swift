import Foundation

enum PageSkewChecks {
    static func run() {
        fiveLongLinesGiveTheirAngle(3.0, pixelWidth: 1240, pixelHeight: 1754)
        fiveLongLinesGiveTheirAngle(-4.0, pixelWidth: 1240, pixelHeight: 1754)
        fiveLongLinesGiveTheirAngle(3.0, pixelWidth: 3000, pixelHeight: 1000)
        fourLongLinesGiveNoAngle()
        narrowLinesDoNotCount()
        oneSteepLineDoesNotMoveTheAngle()
    }

    static func fiveLongLinesGiveTheirAngle(_ degrees: Double, pixelWidth: Int, pixelHeight: Int) {
        let text = SkewedLines.text(5, atDegrees: degrees, pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        let skew = PageSkew.degrees(of: text, pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        expect(
            skew.map { abs($0 - degrees) < 0.01 } == true,
            "five long lines at \(degrees) deg on a \(pixelWidth) x \(pixelHeight) px page give \(degrees) deg")
    }

    static func fourLongLinesGiveNoAngle() {
        let text = SkewedLines.text(4, atDegrees: 3)
        let skew = PageSkew.degrees(of: text, pixelWidth: A4Sheet.width, pixelHeight: A4Sheet.height)
        expect(skew == nil, "a page with only four long lines gives no angle")
    }

    static func narrowLinesDoNotCount() {
        let long = SkewedLines.text(5, atDegrees: 3)
        let narrow = SkewedLines.text(6, atDegrees: -10, widthFraction: 0.15)
        let text = PageText(transcript: "", lines: long.lines + narrow.lines)
        let skew = PageSkew.degrees(of: text, pixelWidth: A4Sheet.width, pixelHeight: A4Sheet.height)
        expect(
            skew.map { abs($0 - 3) < 0.01 } == true,
            "six lines narrower than a fifth of the page do not pull the angle away from the long lines")
    }

    static func oneSteepLineDoesNotMoveTheAngle() {
        let straight = SkewedLines.text(5, atDegrees: 3)
        let steep = SkewedLines.text(1, atDegrees: 40)
        let text = PageText(transcript: "", lines: straight.lines + steep.lines)
        let skew = PageSkew.degrees(of: text, pixelWidth: A4Sheet.width, pixelHeight: A4Sheet.height)
        expect(skew.map { abs($0 - 3) < 0.01 } == true, "one long line at 40 deg does not move the angle of five at 3 deg")
    }
}
