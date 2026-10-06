import Foundation

extension SaneConfigDirectory {
    static let fallbackFolderName = "SamsungScan"

    // So that a test build with its own bundle identifier keeps its own file.
    static var forApp: SaneConfigDirectory {
        let folder = Bundle.main.bundleIdentifier ?? fallbackFolderName
        return SaneConfigDirectory(url: .applicationSupportDirectory.appending(path: folder).appending(path: "sane.d"))
    }
}
