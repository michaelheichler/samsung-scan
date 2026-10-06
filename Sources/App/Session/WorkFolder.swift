import Foundation

struct WorkFolder: Sendable {
    let url: URL

    init(root: URL = .temporaryDirectory) {
        url = root.appending(path: "SamsungScan-\(ProcessInfo.processInfo.processIdentifier)")
    }

    func makeBatchFolderURL() -> URL {
        url.appending(path: UUID().uuidString)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
