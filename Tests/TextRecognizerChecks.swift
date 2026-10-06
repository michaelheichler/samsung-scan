import AppKit
import Foundation

enum TextRecognizerChecks {
    static func run() async {
        let folder = TemporaryFolder.make()
        let page = SamplePage.render(in: folder)
        await recognizedPageHoldsEveryDrawnLine(page)
        await recognizedLinesSitWhereTheyWereDrawn(page)
        await cancelledRecognitionThrowsCancellationError(page)
    }

    static func recognizedPageHoldsEveryDrawnLine(_ page: URL) async {
        let text = try? await TextRecognizer.recognize(fileAt: page)
        let transcript = text?.transcript ?? ""
        let recognized = text?.lines.map(\.text).sorted() ?? []
        expect(
            SamplePage.lines.allSatisfy { transcript.contains($0.text) },
            "the transcript of a German and English page holds every drawn line")
        expect(
            recognized == SamplePage.lines.map(\.text).sorted(),
            "every drawn line comes back as one recognized line with the same text")
    }

    static func recognizedLinesSitWhereTheyWereDrawn(_ page: URL) async {
        let recognized = (try? await TextRecognizer.recognize(fileAt: page))?.lines ?? []
        let placed = SamplePage.lines.allSatisfy { drawn in
            recognized.contains { $0.text == drawn.text && sits($0, at: drawn) }
        }
        expect(placed, "each recognized line starts at the drawn x and baseline, origin bottom left")
        expect(
            !recognized.isEmpty && recognized.allSatisfy(isUpright),
            "each recognized line has its top corners above and its right corners right of the others")
    }

    static func cancelledRecognitionThrowsCancellationError(_ page: URL) async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await TextRecognizer.recognize(fileAt: page)
        }
        let error = await caughtError { _ = try await task.value }
        expect(error is CancellationError, "recognition inside a cancelled task throws CancellationError")
    }

    // So that descenders and box padding pass, a corner may miss by one font size.
    private static func sits(_ line: RecognizedLine, at drawn: SamplePage.Line) -> Bool {
        func near(_ corner: Double, _ drawn: Double, on side: Double) -> Bool {
            abs(corner * side - drawn) < SamplePage.fontSize
        }
        return near(line.bottomLeft.x, drawn.x, on: SamplePage.width) && near(line.topLeft.x, drawn.x, on: SamplePage.width)
            && near(line.bottomLeft.y, drawn.baseline, on: SamplePage.height)
            && near(line.bottomRight.y, drawn.baseline, on: SamplePage.height)
    }

    private static func isUpright(_ line: RecognizedLine) -> Bool {
        line.topLeft.y > line.bottomLeft.y && line.topRight.y > line.bottomRight.y
            && line.topRight.x > line.topLeft.x && line.bottomRight.x > line.bottomLeft.x
    }
}

private enum SamplePage {
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

    static func render(in folder: URL) -> URL {
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
        let url = folder.appending(path: "invoice.png")
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
        return url
    }
}
