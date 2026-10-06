import CoreGraphics
import Foundation
import PDFKit

enum SearchablePDFChecks {
    static func run() async {
        let folder = TemporaryFolder.make()
        let page = ScannedPage(file: SamplePage.render(in: folder, as: .jpeg), resolution: resolution, region: shortRegion)
        let text = (try? await TextRecognizer.recognize(fileAt: page.file)) ?? PageText(transcript: "", lines: [])
        searchablePDFHoldsEveryDrawnLine(page, text)
        foundWordsLieInsideTheirRecognizedLine(page, text)
        textLayerAddsNoVisibleMarks(page, text)
        pageWithoutTextExportsWithoutText()
    }

    private static let resolution = 150
    // So that the top-aligned image overhangs the page, the region is shorter than A4.
    private static let shortRegion = ScanRegion(widthMillimeters: 210, heightMillimeters: 280)

    static func searchablePDFHoldsEveryDrawnLine(_ page: ScannedPage, _ text: PageText) {
        let document = written(page, texts: [page.id: text]).flatMap(PDFDocument.init(url:))
        let content = document?.string ?? ""
        expect(
            SamplePage.lines.allSatisfy { content.contains($0.text) },
            "a PDF written with the recognized text of a page reads back every drawn line")
    }

    static func foundWordsLieInsideTheirRecognizedLine(_ page: ScannedPage, _ text: PageText) {
        let document = written(page, texts: [page.id: text]).flatMap(PDFDocument.init(url:))
        let words = text.lines.flatMap { $0.text.split(separator: " ").map(String.init) }
        let placed = document.flatMap { document in
            document.page(at: 0).map { pdfPage in
                words.allSatisfy { word in
                    let found = document.findString(word, withOptions: [])
                    return !found.isEmpty && found.allSatisfy { selection in
                        text.lines.contains { $0.text.contains(word) && box(of: $0).contains(selection.bounds(for: pdfPage)) }
                    }
                }
            }
        }
        expect(
            !words.isEmpty && placed == true,
            "every word found in the PDF lies inside its recognized line on the top-aligned image")
    }

    static func textLayerAddsNoVisibleMarks(_ page: ScannedPage, _ text: PageText) {
        let withText = rendered(written(page, texts: [page.id: text], named: "with text.pdf"))
        let withoutText = rendered(written(page, named: "without text.pdf"))
        expect(
            !text.lines.isEmpty && !withText.isEmpty && withText == withoutText,
            "the text layer leaves the rendered pixels of the PDF page unchanged")
    }

    static func pageWithoutTextExportsWithoutText() {
        let folder = TemporaryFolder.make()
        let pages = TestImage.scannedA4Pages(2, in: folder)
        let file = try? PageExporter(format: .pdf)
            .export(pages, texts: [pages[0].id: invoice], into: folder, name: ExportFileName(date: .now)).first
        let document = file.flatMap(PDFDocument.init(url:))
        expect(
            document?.page(at: 0)?.string?.contains(invoice.transcript) == true,
            "a PDF export carries the text of a page that has one")
        expect(
            document?.pageCount == 2 && (document?.page(at: 1)?.string ?? "").isEmpty,
            "a PDF export leaves a page without recognized text free of text")
    }

    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412",
        lines: [RecognizedLine(
            text: "Rechnung Nr. 2026-0412", topLeft: CGPoint(x: 0.1, y: 0.9), topRight: CGPoint(x: 0.5, y: 0.9),
            bottomRight: CGPoint(x: 0.5, y: 0.88), bottomLeft: CGPoint(x: 0.1, y: 0.88))])

    private static func written(
        _ page: ScannedPage, texts: [ScannedPage.ID: PageText] = [:], named name: String = "scan.pdf"
    ) -> URL? {
        let file = TemporaryFolder.make().appending(path: name)
        return (try? PDFWriter.write([page], texts: texts, to: file)).map { file }
    }

    // Because PDFWriter aligns the image top with the page top.
    private static func box(of line: RecognizedLine) -> CGRect {
        let imageWidth = SamplePage.width * 72 / Double(resolution)
        let imageHeight = SamplePage.height * 72 / Double(resolution)
        let imageBottom = shortRegion.heightMillimeters / 25.4 * 72 - imageHeight
        let corners = [line.topLeft, line.topRight, line.bottomRight, line.bottomLeft]
        let xs = corners.map { $0.x * imageWidth }
        let ys = corners.map { imageBottom + $0.y * imageHeight }
        let tight = CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
        return tight.insetBy(dx: -1, dy: -1)
    }

    private static func rendered(_ pdf: URL?) -> [UInt8] {
        guard let pdf, let page = CGPDFDocument(pdf as CFURL)?.page(at: 1) else { return [] }
        let box = page.getBoxRect(.mediaBox)
        let width = Int(box.width.rounded(.up))
        let height = Int(box.height.rounded(.up))
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            context.drawPDFPage(page)
        }
        return bytes
    }
}
