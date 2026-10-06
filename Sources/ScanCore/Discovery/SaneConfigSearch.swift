import Foundation

enum SaneConfigSearch {
    static let debugVariable = "SANE_DEBUG_SANEI_CONFIG"
    static let debugLevel = "5"
    static let pathsMarker = "using config directories"
    static let separator: Character = ":"

    // So that the list matches what scanimage reads, whatever prefix built it.
    static func directories(inDebugOutput text: String) -> [String]? {
        let line = text.split(whereSeparator: \.isNewline).first { $0.contains(pathsMarker) }
        guard let line, let marker = line.firstRange(of: pathsMarker) else { return nil }
        let directories = line[marker.upperBound...]
            .trimmingCharacters(in: .whitespaces)
            .split(separator: separator)
            .map(String.init)
        return directories.isEmpty ? nil : directories
    }

    static func firstFile(named name: String, in directories: [String]) -> URL? {
        directories
            .map { URL(filePath: $0).appending(path: name) }
            .first { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
    }
}
