import Foundation

public enum ScanImageLocator {
    // So that apps started from Finder, whose PATH lacks Homebrew, still find it.
    static let fallbackDirectories = ["/opt/homebrew/bin", "/usr/local/bin"]
    static let executableName = "scanimage"

    public static func locate(searchPath: String? = ProcessInfo.processInfo.environment["PATH"]) -> URL? {
        let directories = (searchPath ?? "").split(separator: ":").map(String.init) + fallbackDirectories
        return directories
            .map { URL(filePath: $0).appending(path: executableName) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path(percentEncoded: false)) }
    }
}
