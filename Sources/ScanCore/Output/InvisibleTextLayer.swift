import CoreGraphics
import CoreText
import Foundation

// So that search and selection in a PDF find the words the scan shows.
enum InvisibleTextLayer {
    private static let fontName = "Helvetica"

    static func draw(_ text: PageText, over imageFrame: CGRect, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setTextDrawingMode(.invisible)
        for line in text.lines {
            draw(line, over: imageFrame, in: context)
        }
    }

    private static func draw(_ line: RecognizedLine, over frame: CGRect, in context: CGContext) {
        let bottomLeft = point(line.bottomLeft, in: frame)
        let bottomRight = point(line.bottomRight, in: frame)
        let topLeft = point(line.topLeft, in: frame)
        let width = hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)
        let height = hypot(topLeft.x - bottomLeft.x, topLeft.y - bottomLeft.y)
        guard !line.text.isEmpty, width > 0, height > 0 else { return }
        let font = font(fillingHeight: height)
        let typeset = CTLineCreateWithAttributedString(
            NSAttributedString(string: line.text, attributes: [.init(kCTFontAttributeName as String): font]))
        let naturalWidth = CTLineGetTypographicBounds(typeset, nil, nil, nil)
        guard naturalWidth > 0 else { return }
        context.saveGState()
        defer { context.restoreGState() }
        // Because the text matrix scales glyph shapes but not their advances.
        context.translateBy(x: bottomLeft.x, y: bottomLeft.y)
        context.rotate(by: atan2(bottomRight.y - bottomLeft.y, bottomRight.x - bottomLeft.x))
        context.scaleBy(x: width / naturalWidth, y: 1)
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: 0, y: CTFontGetDescent(font))
        CTLineDraw(typeset, context)
    }

    // So that the glyph boxes span the line box from descender to ascender.
    private static func font(fillingHeight height: CGFloat) -> CTFont {
        let unit = CTFontCreateWithName(fontName as CFString, 1, nil)
        let unitHeight = CTFontGetAscent(unit) + CTFontGetDescent(unit)
        return CTFontCreateWithName(fontName as CFString, height / unitHeight, nil)
    }

    // Because Vision corners are normalized to the image with the origin bottom left.
    private static func point(_ normalized: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: frame.minX + normalized.x * frame.width, y: frame.minY + normalized.y * frame.height)
    }
}
