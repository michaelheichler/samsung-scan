import Foundation

enum ScanRegionPaperChecks {
    static func run() {
        regionWithinHalfMillimeterMatchesA4()
        regionBeyondHalfMillimeterDoesNotMatchA4()
        offsetRegionDoesNotMatchA4()
        fullGlassRegionMatchesFullArea()
        fullAreaWinsOverPaperOfSameSize()
        oddRegionMatchesNothing()
        a4At300DpiHasA4Pixels()
        a4At75DpiHasDraftPixels()
    }

    private static let glass = ScanArea(widthMillimeters: 216.069, heightMillimeters: 297.18)
    private static let a4 = PaperSize(id: "iso-a4", name: "A4", widthMillimeters: 210, heightMillimeters: 297, family: .isoA)

    static func regionWithinHalfMillimeterMatchesA4() {
        expect(ScanRegion(widthMillimeters: 210.4, heightMillimeters: 297).matches(a4), "a 210.4 mm wide region at the corner is A4")
    }

    static func regionBeyondHalfMillimeterDoesNotMatchA4() {
        expect(!ScanRegion(widthMillimeters: 210.6, heightMillimeters: 297).matches(a4), "a 210.6 mm wide region is not A4")
    }

    static func offsetRegionDoesNotMatchA4() {
        let offset = ScanRegion(leftMillimeters: 10, widthMillimeters: 210, heightMillimeters: 297)
        expect(!offset.matches(a4), "an A4 sized region 10 mm from the left is not A4")
    }

    private static func flatbedPapers() -> [PaperSize] {
        PaperCatalogChecks.bundledCatalog()?.sizes(fitting: glass) ?? []
    }

    static func fullGlassRegionMatchesFullArea() {
        let region = ScanRegion(widthMillimeters: 216.069, heightMillimeters: 297.18)
        expect(region.matchingPaper(in: flatbedPapers())?.id == "full-area", "a region over the whole glass is the full area")
    }

    static func fullAreaWinsOverPaperOfSameSize() {
        let area = ScanArea(widthMillimeters: 210.3, heightMillimeters: 297.2)
        let papers = PaperCatalogChecks.bundledCatalog()?.sizes(fitting: area) ?? []
        let region = ScanRegion(widthMillimeters: 210.3, heightMillimeters: 297.2)
        expect(region.matchingPaper(in: papers)?.id == "full-area", "a region that is both the full area and A4 is the full area")
    }

    static func oddRegionMatchesNothing() {
        let region = ScanRegion(widthMillimeters: 120, heightMillimeters: 90)
        expect(region.matchingPaper(in: flatbedPapers()) == nil, "a 120 x 90 mm region matches no paper")
    }

    static func a4At300DpiHasA4Pixels() {
        let pixels = ScanRegion(paper: a4).pixelSize(resolution: 300)
        expect(pixels.width == 2480 && pixels.height == 3508, "A4 at 300 dpi is 2480 x 3508 px")
    }

    static func a4At75DpiHasDraftPixels() {
        let pixels = ScanRegion(paper: a4).pixelSize(resolution: 75)
        expect(pixels.width == 620 && pixels.height == 877, "A4 at 75 dpi is 620 x 877 px")
    }
}
