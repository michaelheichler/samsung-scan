import Foundation

public enum PaperCatalogError: Error, Equatable, LocalizedError {
    case resourceNotFound(fileName: String, searched: [URL])

    public var errorDescription: String? {
        switch self {
        case let .resourceNotFound(fileName, searched):
            let places = searched.isEmpty
                ? "no candidate folder"
                : searched.map { $0.path(percentEncoded: false) }.joined(separator: ", ")
            return "\(fileName) was not found. Searched: \(places). "
                + "Install the app bundle or set \(PaperCatalog.resourcesEnvironmentKey) "
                + "to the folder that contains \(fileName)."
        }
    }
}
