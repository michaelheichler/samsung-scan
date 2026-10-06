import Foundation

public struct PaperSize: Codable, Hashable, Identifiable, Sendable {
    public static let fullAreaID = "full-area"

    public let id: String
    public let name: String
    public let widthMillimeters: Double
    public let heightMillimeters: Double
    public let family: PaperFamily

    public init(
        id: String,
        name: String,
        widthMillimeters: Double,
        heightMillimeters: Double,
        family: PaperFamily
    ) {
        self.id = id
        self.name = name
        self.widthMillimeters = widthMillimeters
        self.heightMillimeters = heightMillimeters
        self.family = family
    }

    public static func fullArea(_ area: ScanArea) -> PaperSize {
        PaperSize(
            id: fullAreaID,
            name: "Full scan area",
            widthMillimeters: area.widthMillimeters,
            heightMillimeters: area.heightMillimeters,
            family: .other
        )
    }

    public var areaSquareMillimeters: Double {
        widthMillimeters * heightMillimeters
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case widthMillimeters = "widthMM"
        case heightMillimeters = "heightMM"
        case family
    }
}
