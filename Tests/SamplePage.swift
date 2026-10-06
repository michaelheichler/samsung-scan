import AppKit
import Foundation

enum SamplePage {
    struct Line {
        let text: String
        let x: Double
        let baseline: Double
    }

    static let width = 1240.0
    static let height = 1754.0
    static let fontSize = 28.0

    // So that a flipped y axis fails, every line sits in the upper half of the page.
    static let lines = [
        Line(text: "Rechnung Nr. 2026-0412", x: 100, baseline: 1580),
        Line(text: "Invoice for consulting services", x: 160, baseline: 1420),
        Line(text: "Gesamtbetrag: 129,90 EUR", x: 420, baseline: 1260),
        Line(text: "Bitte überweisen Sie den Betrag bis zum 30. Oktober", x: 100, baseline: 1100),
        Line(text: "Thank you for your business", x: 240, baseline: 940),
    ]

    static func render(in folder: URL, as type: NSBitmapImageRep.FileType = .png) -> URL {
        let font = NSFont.systemFont(ofSize: fontSize)
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        for line in lines {
            NSAttributedString(string: line.text, attributes: [.font: font, .foregroundColor: NSColor.black])
                .draw(at: NSPoint(x: line.x, y: line.baseline + font.descender))
        }
        NSGraphicsContext.restoreGraphicsState()
        let url = folder.appending(path: type == .jpeg ? "invoice.jpg" : "invoice.png")
        try! bitmap.representation(using: type, properties: [.compressionFactor: 1.0])!.write(to: url)
        return url
    }
}
