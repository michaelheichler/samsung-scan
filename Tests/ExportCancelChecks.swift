import Foundation

enum ExportCancelChecks {
    static func run() async {
        await cancelledImageExportWritesNothing()
        await cancelledPdfExportWritesNothing()
        await uncancelledExportWritesEveryPage()
    }

    private static let name = ExportFileName(date: try! Date("2026-10-05T21:30:00Z", strategy: .iso8601), timeZone: .gmt)

    private struct Outcome: Sendable {
        let files: [String]
        let error: (any Error)?
    }

    private static func export(_ format: ExportFormat, cancelled: Bool) async -> Outcome {
        let folder = TemporaryFolder.make()
        let pages = TestImage.scannedA4Pages(3, in: folder)
        let output = folder.appending(path: "export")
        try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let task = Task {
            withUnsafeCurrentTask { current in
                _ = cancelled ? current?.cancel() : ()
            }
            return try PageExporter(format: format).export(pages, into: output, name: name)
        }
        let error = await caughtError { _ = try await task.value }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: output.path(percentEncoded: false))) ?? []
        return Outcome(files: files.sorted(), error: error)
    }

    static func cancelledImageExportWritesNothing() async {
        let outcome = await export(.png, cancelled: true)
        expect(outcome.error is CancellationError, "a cancelled PNG export ends with CancellationError")
        expect(outcome.files.isEmpty, "a cancelled PNG export leaves no files")
    }

    static func cancelledPdfExportWritesNothing() async {
        let outcome = await export(.pdf, cancelled: true)
        expect(outcome.error is CancellationError, "a cancelled PDF export ends with CancellationError")
        expect(outcome.files.isEmpty, "a cancelled PDF export leaves no PDF file")
    }

    static func uncancelledExportWritesEveryPage() async {
        let outcome = await export(.png, cancelled: false)
        let expected = (1...3).map { "Scan 2026-10-05 21.30 - Page \($0).png" }
        expect(outcome.error == nil && outcome.files == expected, "an export that runs to the end writes all three pages")
    }
}
