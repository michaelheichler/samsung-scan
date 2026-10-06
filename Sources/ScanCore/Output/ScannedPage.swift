import Foundation

public struct ScannedPage: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let file: URL
    public let resolution: Int
    public let region: ScanRegion?

    public init(id: UUID = UUID(), file: URL, resolution: Int, region: ScanRegion? = nil) {
        self.id = id
        self.file = file
        self.resolution = resolution
        self.region = region
    }
}
