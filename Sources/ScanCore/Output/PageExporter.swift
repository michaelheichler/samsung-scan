import Foundation

public struct PageExporter: Sendable {
    public static let defaultJPEGQuality = 0.85

    public let format: ExportFormat
    public let jpegQuality: Double
    // So that a check can stop or fail the export between two documents.
    var documentWritten: @Sendable () throws -> Void = {}

    public init(format: ExportFormat, jpegQuality: Double = Self.defaultJPEGQuality) {
        self.format = format
        self.jpegQuality = jpegQuality
    }

    public func export(
        _ pages: [ScannedPage], texts: [ScannedPage.ID: PageText] = [:], into folder: URL, name: ExportFileName
    ) throws -> [URL] {
        try export(ExportPlan(documents: [ExportDocument(pages: pages, name: name)]), texts: texts, into: folder)
    }

    public func export(_ plan: ExportPlan, texts: [ScannedPage.ID: PageText] = [:], into folder: URL) throws -> [URL] {
        guard !plan.documents.isEmpty else { throw PageExporterError.noPages }
        var written: [URL] = []
        do {
            for document in plan.documents {
                try Task.checkCancellation()
                try writeFiles(of: document.pages, texts: texts, into: folder, name: document.name, recording: &written)
                try documentWritten()
            }
            return written
        } catch {
            // So that a failed or cancelled export leaves no partial files behind.
            Self.remove(written)
            throw error
        }
    }

    public static func remove(_ files: [URL]) {
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func writeFiles(
        of pages: [ScannedPage], texts: [ScannedPage.ID: PageText], into folder: URL, name: ExportFileName,
        recording written: inout [URL]
    ) throws {
        guard format.writesOneFilePerPage else {
            let file = Self.availableFile(in: folder, named: name.document(as: format))
            written.append(file)
            try PDFWriter.write(pages, texts: texts, to: file)
            try Task.checkCancellation()
            return
        }
        for (index, page) in pages.enumerated() {
            let file = Self.availableFile(in: folder, named: name.page(index + 1, as: format))
            written.append(file)
            try write(page, to: file)
            try Task.checkCancellation()
        }
    }

    public func write(_ page: ScannedPage, to destination: URL) throws {
        if format.writesOneFilePerPage {
            try ImageWriter.write(page, as: format, quality: jpegQuality, to: destination)
        } else {
            try PDFWriter.write([page], to: destination)
        }
    }

    // So that a second export in the same minute never overwrites the first.
    static func availableFile(in folder: URL, named name: String) -> URL {
        let first = folder.appending(path: name)
        let stem = first.deletingPathExtension().lastPathComponent
        var candidate = first
        var copy = 1
        while FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            copy += 1
            candidate = folder.appending(path: "\(stem) \(copy)").appendingPathExtension(first.pathExtension)
        }
        return candidate
    }
}
