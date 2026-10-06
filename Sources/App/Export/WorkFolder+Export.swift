import Foundation

extension WorkFolder {
    func makeExportFolder() throws -> URL {
        let folder = url.appending(path: "Export").appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
