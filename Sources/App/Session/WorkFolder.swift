import Foundation

struct WorkFolder: Sendable {
    let url: URL

    init(root: URL = .temporaryDirectory) {
        url = root.appending(path: "SamsungScan-\(ProcessInfo.processInfo.processIdentifier)")
    }

    func makeBatchFolderURL() -> URL {
        url.appending(path: UUID().uuidString)
    }

    var correctionsFolder: URL {
        url.appending(path: "Corrected")
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
