import Foundation

struct ExportJob: Sendable {
    let pages: [ScannedPage]
    let exporter: PageExporter
    let name: ExportFileName
    let makesTextSearchable: Bool
    var texts: [ScannedPage.ID: PageText] = [:]

    var writesSeveralFiles: Bool {
        exporter.format.writesOneFilePerPage && pages.count > 1
    }

    var needsPageText: Bool {
        makesTextSearchable && exporter.format == .pdf
    }

    // So that write errors reach the sheet before any save panel opens.
    @concurrent func stage(in workFolder: WorkFolder) async throws -> ExportedFile {
        let files = try exporter.export(pages, texts: texts, into: workFolder.makeExportFolder(), name: name)
        guard let file = files.first else { throw PageExporterError.noPages }
        return ExportedFile(data: try Data(contentsOf: file), fileName: file.lastPathComponent)
    }

    @concurrent func write(into folder: URL) async throws -> [URL] {
        let isScoped = folder.startAccessingSecurityScopedResource()
        defer {
            if isScoped { folder.stopAccessingSecurityScopedResource() }
        }
        return try exporter.export(pages, texts: texts, into: folder, name: name)
    }
}
