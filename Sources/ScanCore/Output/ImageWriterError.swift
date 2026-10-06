import Foundation

public enum ImageWriterError: LocalizedError, Equatable, Sendable {
    case cannotCreateFile(fileName: String)
    case damagedPage(fileName: String)

    public var errorDescription: String? {
        switch self {
        case .cannotCreateFile(let fileName):
            "The image \(fileName) cannot be created."
        case .damagedPage(let fileName):
            "Page \(fileName) is damaged."
        }
    }
}
