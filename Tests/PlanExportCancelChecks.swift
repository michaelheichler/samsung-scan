import Foundation

enum PlanExportCancelChecks {
    static func run() async {
        await checkCancelledPlanWritesNothing(.pdf)
        await checkCancelledPlanWritesNothing(.png)
    }

    private struct Outcome: Sendable {
        let files: [String]
        let error: (any Error)?
    }

    private static func cancelledExport(_ format: ExportFormat) async -> Outcome {
        let documents = (1...3).map { hour in
            ExportDocument(
                pages: TestImage.scannedA4Pages(2, in: TemporaryFolder.make()),
                name: ExportFileName(date: Date(timeIntervalSince1970: Double(hour) * 3600), timeZone: .gmt))
        }
        let output = TemporaryFolder.make()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try PageExporter(format: format).export(ExportPlan(documents: documents), into: output)
        }
        let error = await caughtError { _ = try await task.value }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: output.path(percentEncoded: false))) ?? []
        return Outcome(files: files, error: error)
    }

    static func checkCancelledPlanWritesNothing(_ format: ExportFormat) async {
        let outcome = await cancelledExport(format)
        expect(
            outcome.error is CancellationError && outcome.files.isEmpty,
            "a cancelled \(format.name) export of three documents ends with CancellationError and leaves no files")
    }
}
