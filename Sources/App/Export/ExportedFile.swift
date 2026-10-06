import SwiftUI
import UniformTypeIdentifiers

struct ExportedFile: FileDocument {
    static let readableContentTypes = ExportFormat.allCases.map(\.contentType)

    let data: Data
    let fileName: String

    init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.init(data: data, fileName: configuration.file.preferredFilename ?? "")
    }

    // Because a nil preferredFilename makes NSFileWrapper raise (ISS-004).
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = FileWrapper(regularFileWithContents: data)
        wrapper.preferredFilename = fileName
        return wrapper
    }
}
