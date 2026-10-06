import Foundation

public struct ScanArea: Hashable, Sendable {
    public let widthMillimeters: Double
    public let heightMillimeters: Double

    public init(widthMillimeters: Double, heightMillimeters: Double) {
        self.widthMillimeters = widthMillimeters
        self.heightMillimeters = heightMillimeters
    }

    public func contains(width: Double, height: Double, tolerance: Double = 0) -> Bool {
        width <= widthMillimeters + tolerance && height <= heightMillimeters + tolerance
    }
}
