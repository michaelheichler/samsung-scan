import Foundation

public enum PDFWriterError: LocalizedError, Equatable, Sendable {
    case cannotCreateFile
    case damagedPage(fileName: String)

    public var errorDescription: String? {
        switch self {
        case .cannotCreateFile:
            "The PDF file cannot be created."
        case .damagedPage(let fileName):
            "Page \(fileName) is damaged."
        }
    }
}
