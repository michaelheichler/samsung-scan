import Foundation

enum PDFWriterChecks {
    static func run() {
        a4At300DpiBecomesA4PageInPoints()
        unwritableDestinationCannotBeCreated()
        pageThatIsNotJpegIsDamaged()
    }

    static func a4At300DpiBecomesA4PageInPoints() {
        let size = PDFWriter.pageSizeInPoints(pixelWidth: 2480, pixelHeight: 3508, resolution: 300)
        expect(abs(size.width - 595.2) < 0.5 && abs(size.height - 841.9) < 0.5, "A4 at 300 dpi gives an A4 PDF page")
    }

    static func unwritableDestinationCannotBeCreated() {
        let destination = URL(filePath: "/samsungscan-missing-folder/scan.pdf")
        let error = Result { try PDFWriter.write([], to: destination) }.failure
        expect(error as? PDFWriterError == .cannotCreateFile, "a PDF in a missing folder cannot be created")
        expect(error?.localizedDescription == "The PDF file cannot be created.", "a PDF that cannot be created says so in English")
    }

    static func pageThatIsNotJpegIsDamaged() {
        let folder = TemporaryFolder.make()
        let page = folder.appending(path: "page001.jpg")
        try! Data("not a jpeg".utf8).write(to: page)
        let pages = [ScannedPage(file: page, resolution: 300)]
        let error = Result { try PDFWriter.write(pages, to: folder.appending(path: "scan.pdf")) }.failure
        expect(error as? PDFWriterError == .damagedPage(fileName: "page001.jpg"), "a page that is not a JPEG is damaged")
        expect(error?.localizedDescription == "Page page001.jpg is damaged.", "a damaged page is named in the message")
    }
}

extension Result {
    var failure: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
