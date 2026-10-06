import Foundation

struct ExportJob: Sendable {
    let pages: [ScannedPage]
    let exporter: PageExporter
    let name: ExportFileName

    var writesSeveralFiles: Bool {
        exporter.format.writesOneFilePerPage && pages.count > 1
    }

    // So that write errors reach the sheet before any save panel opens.
    @concurrent func stage(in workFolder: WorkFolder) async throws -> ExportedFile {
        let files = try exporter.export(pages, into: workFolder.makeExportFolder(), name: name)
        guard let file = files.first else { throw PageExporterError.noPages }
        return ExportedFile(data: try Data(contentsOf: file), fileName: file.lastPathComponent)
    }

    @concurrent func write(into folder: URL) async throws -> [URL] {
        let isScoped = folder.startAccessingSecurityScopedResource()
        defer {
            if isScoped { folder.stopAccessingSecurityScopedResource() }
        }
        return try exporter.export(pages, into: folder, name: name)
    }
}
