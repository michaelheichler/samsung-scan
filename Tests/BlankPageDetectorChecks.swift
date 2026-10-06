import AppKit
import Foundation

enum BlankPageDetectorChecks {
    static func run() async {
        let folder = TemporaryFolder.make()
        await whitePageIsBlank(in: folder)
        await darkScannerBorderLeavesThePageBlank(in: folder)
        await tintedPaperIsBlank(in: folder)
        await oneShortLineOfTextIsNotBlank(in: folder)
        await lightGrayPhotoIsNotBlank(in: folder)
        await unreadableFileThrows(in: folder)
    }

    static func whitePageIsBlank(in folder: URL) async {
        let page = A4Page.jpeg(named: "white", in: folder) { context in
            A4Page.fillPaper(context)
        }
        let blank = try? await BlankPageDetector.isBlank(fileAt: page)
        expect(blank == true, "a white A4 page counts as blank")
    }

    static func darkScannerBorderLeavesThePageBlank(in folder: URL) async {
        let page = A4Page.jpeg(named: "border", in: folder) { context in
            context.setFillColor(gray: 0.15, alpha: 1)
            context.fill(A4Page.bounds)
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(A4Page.bounds.insetBy(dx: 40, dy: 40))
        }
        let blank = try? await BlankPageDetector.isBlank(fileAt: page)
        expect(blank == true, "a white page with a dark 40 px scanner border on every side counts as blank")
    }

    static func tintedPaperIsBlank(in folder: URL) async {
        let page = A4Page.jpeg(named: "tinted", in: folder) { context in
            context.setFillColor(gray: 0.8, alpha: 1)
            context.fill(A4Page.bounds)
        }
        let blank = try? await BlankPageDetector.isBlank(fileAt: page)
        expect(blank == true, "an empty page of evenly tinted paper counts as blank")
    }

    static func oneShortLineOfTextIsNotBlank(in folder: URL) async {
        let page = A4Page.jpeg(named: "one-line", in: folder) { context in
            A4Page.fillPaper(context)
            let font = NSFont.systemFont(ofSize: A4Page.tenPointInPixels)
            NSAttributedString(string: "Page two", attributes: [.font: font, .foregroundColor: NSColor.black])
                .draw(at: NSPoint(x: 150, y: 1600))
        }
        let blank = try? await BlankPageDetector.isBlank(fileAt: page)
        expect(blank == false, "a page with one short line of 10 pt text does not count as blank")
    }

    static func lightGrayPhotoIsNotBlank(in folder: URL) async {
        let page = A4Page.jpeg(named: "photo", in: folder) { context in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceGray(),
                colors: [CGColor(gray: 0.95, alpha: 1), CGColor(gray: 0.75, alpha: 1)] as CFArray,
                locations: [0, 1])!
            context.drawLinearGradient(
                gradient, start: CGPoint(x: 0, y: A4Page.bounds.maxY), end: .zero, options: [])
            context.setFillColor(gray: 0.62, alpha: 1)
            context.fillEllipse(in: CGRect(x: 300, y: 400, width: 500, height: 300))
        }
        let blank = try? await BlankPageDetector.isBlank(fileAt: page)
        expect(blank == false, "a light gray photo with a gradient and a shape does not count as blank")
    }

    static func unreadableFileThrows(in folder: URL) async {
        let file = folder.appending(path: "not-an-image.jpg")
        try! Data("plain text, no image data".utf8).write(to: file)
        let error = await caughtError { _ = try await BlankPageDetector.isBlank(fileAt: file) }
        expect(error != nil, "blank detection of a file that holds no image throws")
    }
}

// So that every page matches an A4 scan at 150 dpi.
private enum A4Page {
    static let bounds = CGRect(x: 0, y: 0, width: 1240, height: 1754)
    static let tenPointInPixels = 10.0 * 150 / 72

    static func fillPaper(_ context: CGContext) {
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(bounds)
    }

    // Because an RGB bitmap without alpha gives no graphics context.
    static func jpeg(named name: String, in folder: URL, drawing draw: (CGContext) -> Void) -> URL {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(bounds.width), pixelsHigh: Int(bounds.height), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = bounds.size
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        draw(context.cgContext)
        NSGraphicsContext.restoreGraphicsState()
        let url = folder.appending(path: "\(name).jpg")
        try! bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])!.write(to: url)
        return url
    }
}
