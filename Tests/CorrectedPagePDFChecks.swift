import CoreGraphics
import Foundation

@MainActor
enum CorrectedPagePDFChecks {
    static func run() async {
        await trimmedPageGetsPDFPageOfItsImage()
        await straightenedA4PageKeepsA4PDFPage()
    }

    static func trimmedPageGetsPDFPageOfItsImage() async {
        let folder = TemporaryFolder.make()
        let scan = A4Sheet.jpeg(named: "block", in: folder) { context in
            A4Sheet.fillFromTop(CGRect(x: 300, y: 200, width: 500, height: 600), in: context)
        }
        let page = ScannedPage(file: scan, resolution: A4Sheet.resolution, region: TestImage.a4Region)
        let trimmed = try? await PageCorrections(folder: folder).trimmed(page)
        let file = trimmed.flatMap { $0 }
        let box = file.flatMap { mediaBox(of: $0, in: folder) }
        let size = file.flatMap { TestImage.pixelSize(of: $0.file) }
        let expected = size.map { CGSize(width: Double($0.width) * 72 / 150, height: Double($0.height) * 72 / 150) }
        expect(
            box.map { near($0.size, expected ?? .zero) } == true,
            "a trimmed page becomes a PDF page the size of the cropped image at its resolution")
    }

    static func straightenedA4PageKeepsA4PDFPage() async {
        let folder = TemporaryFolder.make()
        let page = ScannedPage(
            file: LetterPage.jpeg(in: folder), resolution: A4Sheet.resolution, region: TestImage.a4Region)
        let straight = try? await PageCorrections(folder: folder)
            .straightened(page, text: SkewedLines.text(6, atDegrees: 3))
        let box = straight.flatMap { $0 }.flatMap { mediaBox(of: $0, in: folder) }
        expect(
            box.map { near($0.size, CGSize(width: 210 * 72 / 25.4, height: 297 * 72 / 25.4)) } == true,
            "a straightened A4 page stays an A4 PDF page")
    }

    private static func mediaBox(of page: ScannedPage, in folder: URL) -> CGRect? {
        let pdf = folder.appending(path: "\(UUID().uuidString).pdf")
        try? PDFWriter.write([page], to: pdf)
        return CGPDFDocument(pdf as CFURL)?.page(at: 1)?.getBoxRect(.mediaBox)
    }

    private static func near(_ size: CGSize, _ expected: CGSize) -> Bool {
        abs(size.width - expected.width) < 0.5 && abs(size.height - expected.height) < 0.5
    }
}
