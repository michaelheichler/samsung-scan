import Foundation

enum PageFormatChecks {
    static func run() {
        a4ScanAt75DpiIsNamedA4()
        landscapeScanKeepsPaperName()
        unknownSizeIsNamedInMillimeters()
        zeroResolutionGivesFiniteSize()
        emptyImageHasSquareAspect()
        regionFormatUsesRegionSize()
    }

    private static let catalog = PaperCatalogChecks.bundledCatalog()

    static func a4ScanAt75DpiIsNamedA4() {
        let format = PageFormat(pixelWidth: 620, pixelHeight: 891, resolution: 75, catalog: catalog)
        expect(format.name == "A4", "a 620 x 891 px page at 75 dpi is named A4")
        expect(format.widthMillimeters == 210 && format.heightMillimeters == 297, "a scanned A4 page reports 210 x 297 mm")
        expect(abs(format.aspectRatio - 210.0 / 297.0) < 0.0005, "a scanned A4 page has the A4 aspect ratio")
    }

    static func landscapeScanKeepsPaperName() {
        let format = PageFormat(pixelWidth: 891, pixelHeight: 620, resolution: 75, catalog: catalog)
        expect(format.name == "A4", "a landscape A4 scan is still named A4")
        expect(format.widthMillimeters == 297 && format.heightMillimeters == 210, "a landscape A4 scan reports 297 x 210 mm")
    }

    static func unknownSizeIsNamedInMillimeters() {
        let format = PageFormat(widthMillimeters: 100.6, heightMillimeters: 50.4, catalog: catalog)
        expect(format.paper == nil, "a 100.6 x 50.4 mm page matches no paper")
        expect(format.name == "101 × 50 mm", "an unknown page is named by its rounded size")
    }

    static func zeroResolutionGivesFiniteSize() {
        let format = PageFormat(pixelWidth: 620, pixelHeight: 891, resolution: 0, catalog: catalog)
        expect(format.widthMillimeters.isFinite && format.heightMillimeters.isFinite, "a page with resolution 0 still has a finite size")
    }

    static func emptyImageHasSquareAspect() {
        let format = PageFormat(pixelWidth: 0, pixelHeight: 0, resolution: 75, catalog: catalog)
        expect(format.aspectRatio == 1, "an empty image has aspect ratio 1")
    }

    static func regionFormatUsesRegionSize() {
        let region = ScanRegion(leftMillimeters: 30, topMillimeters: 40, widthMillimeters: 120.4, heightMillimeters: 80)
        let format = PageFormat(region: region, catalog: catalog)
        expect(format.name == "120 × 80 mm", "a region is named by its width and height, not its offset")
        expect(format.widthMillimeters == 120.4, "a region format keeps the region width")
    }
}
