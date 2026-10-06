import CoreGraphics
import Foundation

enum PlanExportChecks {
    static func run() {
        threeDocumentsGiveThreePdfFilesInPlanOrder()
        everyPdfHoldsThePagesOfItsDocument()
        equalNamesStillGiveTwoFiles()
        planWithoutPagesIsRejected()
    }

    private static func name(hour: Int) -> ExportFileName {
        ExportFileName(date: Date(timeIntervalSince1970: Double(hour) * 3600), timeZone: .gmt)
    }

    private static func exported(pageCounts: [Int], names: [ExportFileName]) -> [URL] {
        let documents = zip(pageCounts, names).map {
            ExportDocument(pages: TestImage.scannedA4Pages($0, in: TemporaryFolder.make()), name: $1)
        }
        let output = TemporaryFolder.make()
        return (try? PageExporter(format: .pdf).export(ExportPlan(documents: documents), into: output)) ?? []
    }

    private static func pageCount(of file: URL) -> Int {
        CGPDFDocument(file as CFURL)?.numberOfPages ?? 0
    }

    private static let unsortedNames = [name(hour: 15), name(hour: 9), name(hour: 12)]

    static func threeDocumentsGiveThreePdfFilesInPlanOrder() {
        let files = exported(pageCounts: [2, 1, 3], names: unsortedNames)
        expect(
            files.map(\.lastPathComponent) == unsortedNames.map { $0.document(as: .pdf) },
            "a PDF export of three documents writes three files under their own names in plan order")
    }

    static func everyPdfHoldsThePagesOfItsDocument() {
        let files = exported(pageCounts: [2, 1, 3], names: unsortedNames)
        expect(files.map(pageCount(of:)) == [2, 1, 3], "every PDF of a three document export holds the pages of its document")
    }

    static func equalNamesStillGiveTwoFiles() {
        let shared = name(hour: 9)
        let files = exported(pageCounts: [1, 1], names: [shared, shared])
        expect(
            files.map(\.lastPathComponent) == [shared.document(as: .pdf), "\(shared.stem) 2.pdf"],
            "two documents with the same name give two files, the second numbered 2")
    }

    static func planWithoutPagesIsRejected() {
        let plan = ExportPlan(documents: [ExportDocument(pages: [], name: name(hour: 9))])
        let error = Result { try PageExporter(format: .pdf).export(plan, into: TemporaryFolder.make()) }.failure
        expect(error as? PageExporterError == .noPages, "the exporter rejects a plan whose documents have no pages")
    }
}
