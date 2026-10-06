import Foundation

enum PlanExportCleanupChecks {
    static func run() async {
        await exportCancelledAfterTheFirstDocumentLeavesNoFiles(.pdf)
        await exportCancelledAfterTheFirstDocumentLeavesNoFiles(.png)
        await exportFailingAfterTheFirstDocumentLeavesNoFiles(.pdf)
        await exportFailingAfterTheFirstDocumentLeavesNoFiles(.png)
        await damagedPageInTheSecondDocumentLeavesNoFiles(.pdf)
        await damagedPageInTheSecondDocumentLeavesNoFiles(.png)
    }

    private struct StoppedAfterFirstDocument: Error {}

    private struct Outcome: Sendable {
        let files: [String]
        let error: (any Error)?
    }

    private static func intactDocument(_ hour: Int) -> ExportDocument {
        ExportDocument(pages: TestImage.scannedA4Pages(2, in: TemporaryFolder.make()), name: name(hour))
    }

    private static func name(_ hour: Int) -> ExportFileName {
        ExportFileName(date: Date(timeIntervalSince1970: Double(hour) * 3600), timeZone: .gmt)
    }

    private static func exporter(
        _ format: ExportFormat, afterEachDocument hook: @escaping @Sendable () throws -> Void
    ) -> PageExporter {
        var exporter = PageExporter(format: format)
        exporter.documentWritten = hook
        return exporter
    }

    private static func export(_ documents: [ExportDocument], with exporter: PageExporter) async -> Outcome {
        let output = TemporaryFolder.make()
        let task = Task { try exporter.export(ExportPlan(documents: documents), into: output) }
        let error = await caughtError { _ = try await task.value }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: output.path(percentEncoded: false))) ?? []
        return Outcome(files: files, error: error)
    }

    static func exportCancelledAfterTheFirstDocumentLeavesNoFiles(_ format: ExportFormat) async {
        let cancelling = exporter(format) { withUnsafeCurrentTask { $0?.cancel() } }
        let outcome = await export((1...3).map(intactDocument), with: cancelling)
        expect(
            outcome.error is CancellationError && outcome.files.isEmpty,
            "a \(format.name) export cancelled after its first of three documents leaves no files")
    }

    static func exportFailingAfterTheFirstDocumentLeavesNoFiles(_ format: ExportFormat) async {
        let failing = exporter(format) { throw StoppedAfterFirstDocument() }
        let outcome = await export((1...3).map(intactDocument), with: failing)
        expect(
            outcome.error is StoppedAfterFirstDocument && outcome.files.isEmpty,
            "a \(format.name) export failing after its first of three documents reports the error and leaves no files")
    }

    static func damagedPageInTheSecondDocumentLeavesNoFiles(_ format: ExportFormat) async {
        let missing = ScannedPage(
            file: TemporaryFolder.make().appending(path: "missing.jpg"), resolution: 75, region: TestImage.a4Region)
        let damaged = ExportDocument(pages: [missing], name: name(2))
        let outcome = await export([intactDocument(1), damaged, intactDocument(3)], with: PageExporter(format: format))
        expect(
            outcome.error != nil && outcome.files.isEmpty,
            "a \(format.name) export with a damaged page in its second document fails and leaves no files")
    }
}
