import Foundation

public struct PageFormat: Hashable, Sendable {
    public let widthMillimeters: Double
    public let heightMillimeters: Double
    public let paper: PaperSize?

    public init(widthMillimeters: Double, heightMillimeters: Double, catalog: PaperCatalog?) {
        let paper = catalog?.size(matchingWidth: widthMillimeters, height: heightMillimeters)
        self.paper = paper
        guard let paper else {
            self.widthMillimeters = widthMillimeters
            self.heightMillimeters = heightMillimeters
            return
        }
        let short = min(paper.widthMillimeters, paper.heightMillimeters)
        let long = max(paper.widthMillimeters, paper.heightMillimeters)
        let isLandscape = widthMillimeters > heightMillimeters
        self.widthMillimeters = isLandscape ? long : short
        self.heightMillimeters = isLandscape ? short : long
    }

    public init(pixelWidth: Int, pixelHeight: Int, resolution: Int, catalog: PaperCatalog?) {
        let millimetersPerPixel = Inch.millimeters / Double(max(resolution, 1))
        self.init(
            widthMillimeters: Double(pixelWidth) * millimetersPerPixel,
            heightMillimeters: Double(pixelHeight) * millimetersPerPixel,
            catalog: catalog)
    }

    public init(region: ScanRegion, catalog: PaperCatalog?) {
        self.init(widthMillimeters: region.widthMillimeters, heightMillimeters: region.heightMillimeters, catalog: catalog)
    }

    public var name: String {
        paper?.name ?? "\(Int(widthMillimeters.rounded())) × \(Int(heightMillimeters.rounded())) mm"
    }

    public var aspectRatio: Double {
        heightMillimeters > 0 ? widthMillimeters / heightMillimeters : 1
    }
}
