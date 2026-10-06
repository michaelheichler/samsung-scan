import Foundation

enum PaperCatalogChecks {
    static func run() {
        glassKeepsCommonSizesAndDropsLongOnes()
        feederKeepsLegal()
        sizeWithinHalfMillimeterStillFits()
        sizeBeyondHalfMillimeterIsDropped()
        fullAreaComesFirstWithAreaSize()
        tooSmallAreaStillOffersFullArea()
        bundledCatalogLoadsWithoutAppBundle()
        missingResourceIsReported()
    }

    private static let glass = ScanArea(widthMillimeters: 216.069, heightMillimeters: 297.18)
    private static let feeder = ScanArea(widthMillimeters: 216.069, heightMillimeters: 355.6)

    private static func a4Only() -> PaperCatalog {
        PaperCatalog(sizes: [
            PaperSize(id: "iso-a4", name: "A4", widthMillimeters: 210, heightMillimeters: 297, family: .isoA),
        ])
    }

    static func bundledCatalog() -> PaperCatalog? {
        try? PaperCatalog(contentsOf: PaperCatalog.locateResource(bundleResources: nil))
    }

    private static func bundledIDs(fitting area: ScanArea) -> Set<String> {
        Set(bundledCatalog()?.sizes(fitting: area).map(\.id) ?? [])
    }

    static func glassKeepsCommonSizesAndDropsLongOnes() {
        let ids = bundledIDs(fitting: glass)
        expect(ids.isSuperset(of: ["iso-a4", "iso-a5", "us-letter", "iso-b5"]), "glass offers A4, A5, Letter and B5")
        expect(!ids.contains("us-legal"), "glass hides Legal, which is longer than the glass")
        expect(!ids.contains("iso-a3"), "glass hides A3, which is wider than the glass")
    }

    static func feederKeepsLegal() {
        expect(bundledIDs(fitting: feeder).contains("us-legal"), "feeder offers Legal")
    }

    static func sizeWithinHalfMillimeterStillFits() {
        let area = ScanArea(widthMillimeters: 210, heightMillimeters: 296.5)
        expect(a4Only().sizes(fitting: area).map(\.id).contains("iso-a4"), "A4 fits an area 0.5 mm too short")
    }

    static func sizeBeyondHalfMillimeterIsDropped() {
        let area = ScanArea(widthMillimeters: 210, heightMillimeters: 296.4)
        expect(!a4Only().sizes(fitting: area).map(\.id).contains("iso-a4"), "A4 does not fit an area 0.6 mm too short")
    }

    static func fullAreaComesFirstWithAreaSize() {
        let first = a4Only().sizes(fitting: glass).first
        expect(first?.id == "full-area", "the first preset is the full scan area")
        expect(first?.widthMillimeters == 216.069, "the full area preset has the area width")
        expect(first?.heightMillimeters == 297.18, "the full area preset has the area height")
    }

    static func tooSmallAreaStillOffersFullArea() {
        let tiny = ScanArea(widthMillimeters: 50, heightMillimeters: 50)
        expect(a4Only().sizes(fitting: tiny).map(\.id) == ["full-area"], "an area too small for A4 offers only the full area")
    }

    static func bundledCatalogLoadsWithoutAppBundle() {
        let sizes = bundledCatalog()?.sizes ?? []
        let a4 = sizes.first { $0.id == "iso-a4" }
        let letter = sizes.first { $0.id == "us-letter" }
        expect(!sizes.isEmpty, "bundled catalog loads through SAMSUNGSCAN_RESOURCES")
        expect(Set(sizes.map(\.id)).count == sizes.count, "bundled catalog ids are unique")
        expect(a4?.widthMillimeters == 210 && a4?.heightMillimeters == 297, "bundled A4 is 210 x 297 mm")
        expect(letter?.widthMillimeters == 215.9 && letter?.heightMillimeters == 279.4, "bundled Letter is 215.9 x 279.4 mm")
    }

    static func missingResourceIsReported() {
        let result = Result { try PaperCatalog.locateResource(bundleResources: nil, environment: [:]) }
        expect(
            catalogError(result) == .resourceNotFound(fileName: "PaperSizes.json", searched: []),
            "no bundle and no SAMSUNGSCAN_RESOURCES reports the missing PaperSizes.json")
    }

    private static func catalogError(_ result: Result<URL, any Error>) -> PaperCatalogError? {
        guard case .failure(let error) = result else { return nil }
        return error as? PaperCatalogError
    }
}
