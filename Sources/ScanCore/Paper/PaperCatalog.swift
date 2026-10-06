import Foundation

public struct PaperCatalog: Hashable, Sendable {
    public static let resourceFileName = "PaperSizes.json"
    public static let resourcesEnvironmentKey = "SAMSUNGSCAN_RESOURCES"
    public static let fitTolerance = 0.5

    public let sizes: [PaperSize]

    public init(sizes: [PaperSize]) {
        self.sizes = sizes.sorted { lhs, rhs in
            if lhs.family != rhs.family {
                lhs.family < rhs.family
            } else {
                lhs.areaSquareMillimeters > rhs.areaSquareMillimeters
            }
        }
    }

    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self.init(sizes: try JSONDecoder().decode([PaperSize].self, from: data))
    }

    public static func bundled() throws -> PaperCatalog {
        try PaperCatalog(contentsOf: locateResource())
    }

    public static func locateResource(
        bundleResources: URL? = Bundle.main.resourceURL,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> URL {
        let folders = [bundleResources, environment[resourcesEnvironmentKey].map { URL(filePath: $0) }]
        let candidates = folders.compactMap { $0?.appending(path: resourceFileName) }
        guard let found = candidates.first(where: {
            FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
        }) else {
            throw PaperCatalogError.resourceNotFound(fileName: resourceFileName, searched: candidates)
        }
        return found
    }

    public func sizes(fitting area: ScanArea) -> [PaperSize] {
        let fitting = sizes.filter {
            area.contains(
                width: $0.widthMillimeters,
                height: $0.heightMillimeters,
                tolerance: Self.fitTolerance
            )
        }
        return [.fullArea(area)] + fitting
    }
}
