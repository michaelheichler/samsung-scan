import Foundation

public struct SaneConfigDirectory: Sendable {
    static let environmentVariable = "SANE_CONFIG_DIR"

    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    // So that SANE appends its default directories for every other backend.
    var searchPath: String {
        url.path(percentEncoded: false) + String(SaneConfigSearch.separator)
    }

    var environment: [String: String] {
        [Self.environmentVariable: searchPath]
    }

    func writeXeroxConfig(_ text: String) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try text.write(to: url.appending(path: XeroxConfig.fileName), atomically: true, encoding: .utf8)
    }
}
