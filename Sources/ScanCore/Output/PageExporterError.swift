import Foundation

public enum PageExporterError: LocalizedError, Equatable, Sendable {
    case noPages

    public var errorDescription: String? {
        switch self {
        case .noPages:
            "There are no pages to export."
        }
    }
}
