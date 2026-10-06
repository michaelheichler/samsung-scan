import Foundation

struct ExportJob: Sendable {
    let plan: ExportPlan
    let exporter: PageExporter
    let makesTextSearchable: Bool
    var texts: [ScannedPage.ID: PageText] = [:]

    var pages: [ScannedPage] {
        plan.pages
    }

    var writesSeveralFiles: Bool {
        plan.writesSeveralFiles(as: exporter.format)
    }

    var needsPageText: Bool {
        makesTextSearchable && exporter.format == .pdf
    }

    // So that write errors reach the sheet before any save panel opens.
    @concurrent func stage(in workFolder: WorkFolder) async throws -> ExportedFile {
        let files = try exporter.export(plan, texts: texts, into: workFolder.makeExportFolder())
        guard let file = files.first else { throw PageExporterError.noPages }
        return ExportedFile(data: try Data(contentsOf: file), fileName: file.lastPathComponent)
    }

    @concurrent func write(into folder: URL) async throws -> [URL] {
        let isScoped = folder.startAccessingSecurityScopedResource()
        defer {
            if isScoped { folder.stopAccessingSecurityScopedResource() }
        }
        return try exporter.export(plan, texts: texts, into: folder)
    }
}
