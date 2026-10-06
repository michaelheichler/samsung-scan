import CoreGraphics
import Foundation

enum PageExporterChecks {
    static func run() {
        pdfExportWritesOneA4Document()
        pngExportWritesOnePagePerFile()
        jpegExportWritesOnePagePerFile()
        lowerJpegQualityGivesSmallerFile()
        nameClashGetsNumber()
        fileNameUsesDateAndTime()
        emptyPageListIsRejected()
        damagedPageIsNamed()
        missingFolderCannotTakePdf()
        missingFolderCannotTakeImage()
    }

    private static let name = ExportFileName(date: try! Date("2026-10-05T21:30:00Z", strategy: .iso8601), timeZone: .gmt)

    private static func exported(_ format: ExportFormat, pages count: Int, quality: Double = PageExporter.defaultJPEGQuality) -> [URL] {
        let folder = TemporaryFolder.make()
        let pages = TestImage.scannedA4Pages(count, in: folder)
        let output = folder.appending(path: "export")
        try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        return (try? PageExporter(format: format, jpegQuality: quality).export(pages, into: output, name: name)) ?? []
    }

    private static func pdfPageSizes(_ file: URL?) -> [CGSize] {
        guard let file, let document = CGPDFDocument(file as CFURL) else { return [] }
        return (1...max(document.numberOfPages, 1)).compactMap { document.page(at: $0)?.getBoxRect(.mediaBox).size }
    }

    private static func isA4(_ size: CGSize) -> Bool {
        abs(size.width - 595.28) < 0.01 && abs(size.height - 841.89) < 0.01
    }

    static func pdfExportWritesOneA4Document() {
        let files = exported(.pdf, pages: 3)
        let sizes = pdfPageSizes(files.first)
        expect(files.map(\.lastPathComponent) == ["Scan 2026-10-05 21.30.pdf"], "a PDF export writes one file named after the scan time")
        expect(sizes.count == 3, "a PDF export of three pages holds three pages")
        expect(sizes.allSatisfy(isA4), "every page of an A4 PDF export is 595.28 x 841.89 pt")
    }

    private static func checkImageExport(_ format: ExportFormat, suffix: String) {
        let files = exported(format, pages: 3)
        let expectedNames = (1...3).map { "Scan 2026-10-05 21.30 - Page \($0).\(suffix)" }
        let sizes = files.compactMap(TestImage.pixelSize(of:))
        expect(files.map(\.lastPathComponent) == expectedNames, "a \(format.name) export writes one numbered file per page")
        expect(files.map(TestImage.resolution(of:)) == [75, 75, 75], "a \(format.name) export keeps the 75 dpi scan resolution")
        expect(sizes.count == 3 && sizes.allSatisfy { $0 == (620, 877) }, "a \(format.name) export leaves out the extra scanned lines")
    }

    static func pngExportWritesOnePagePerFile() {
        checkImageExport(.png, suffix: "png")
    }

    static func jpegExportWritesOnePagePerFile() {
        checkImageExport(.jpeg, suffix: "jpg")
    }

    private static func fileSize(_ file: URL?) -> Int {
        file.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize } ?? 0
    }

    static func lowerJpegQualityGivesSmallerFile() {
        let low = fileSize(exported(.jpeg, pages: 1, quality: 0.5).first)
        let high = fileSize(exported(.jpeg, pages: 1, quality: 1.0).first)
        expect(low > 0 && low < high, "a JPEG at quality 0.5 is smaller than at quality 1.0")
    }

    static func nameClashGetsNumber() {
        let folder = TemporaryFolder.make()
        let pages = TestImage.scannedA4Pages(1, in: folder)
        let exporter = PageExporter(format: .pdf)
        _ = try? exporter.export(pages, into: folder, name: name)
        let second = try? exporter.export(pages, into: folder, name: name)
        expect(second?.map(\.lastPathComponent) == ["Scan 2026-10-05 21.30 2.pdf"], "a second export in the same minute gets the number 2")
    }

    static func fileNameUsesDateAndTime() {
        expect(name.stem == "Scan 2026-10-05 21.30", "a scan at 21:30 UTC on 5 October 2026 is named Scan 2026-10-05 21.30")
    }

    static func emptyPageListIsRejected() {
        let error = Result { try PageExporter(format: .pdf).export([], into: TemporaryFolder.make(), name: name) }.failure
        expect(error as? PageExporterError == .noPages, "an export without pages is rejected")
        expect(error?.localizedDescription == "There are no pages to export.", "an export without pages says so in English")
    }

    static func damagedPageIsNamed() {
        let folder = TemporaryFolder.make()
        let file = folder.appending(path: "page001.jpg")
        try! Data("not a jpeg".utf8).write(to: file)
        let pages = [ScannedPage(file: file, resolution: 75)]
        let error = Result { try PageExporter(format: .png).export(pages, into: folder, name: name) }.failure
        expect(error as? ImageWriterError == .damagedPage(fileName: "page001.jpg"), "a PNG export of a page that is not a JPEG names the damaged page")
    }

    private static func exportIntoMissingFolder(_ format: ExportFormat) -> (any Error)? {
        let pages = TestImage.scannedA4Pages(1, in: TemporaryFolder.make())
        let missing = URL(filePath: "/samsungscan-missing-folder")
        return Result { try PageExporter(format: format).export(pages, into: missing, name: name) }.failure
    }

    static func missingFolderCannotTakePdf() {
        expect(exportIntoMissingFolder(.pdf) as? PDFWriterError == .cannotCreateFile, "a PDF export into a missing folder cannot create the file")
    }

    static func missingFolderCannotTakeImage() {
        let error = exportIntoMissingFolder(.png) as? ImageWriterError
        expect(error == .cannotCreateFile(fileName: "Scan 2026-10-05 21.30 - Page 1.png"), "a PNG export into a missing folder names the file it cannot create")
    }
}
