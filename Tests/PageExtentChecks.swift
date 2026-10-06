import Foundation

enum PageExtentChecks {
    static func run() {
        regionPageHasPaperMediaBox()
        pageWithoutRegionUsesImageSize()
        regionPageHidesExtraLines()
        visiblePartNeverExceedsImage()
    }

    private static let file = URL(filePath: "/tmp/page001.jpg")

    private static func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.01
    }

    static func regionPageHasPaperMediaBox() {
        let page = ScannedPage(file: file, resolution: 75, region: TestImage.a4Region)
        let box = page.mediaBox(pixelWidth: 620, pixelHeight: 891)
        expect(isClose(box.width, 595.28) && isClose(box.height, 841.89), "an A4 scan with 14 extra lines gives an A4 PDF page")
    }

    static func pageWithoutRegionUsesImageSize() {
        let box = ScannedPage(file: file, resolution: 75).mediaBox(pixelWidth: 620, pixelHeight: 891)
        expect(isClose(box.width, 595.2) && isClose(box.height, 855.36), "a page without a region is as large as its image")
    }

    static func regionPageHidesExtraLines() {
        let visible = ScannedPage(file: file, resolution: 75, region: TestImage.a4Region).visiblePixels(pixelWidth: 620, pixelHeight: 891)
        expect(visible == CGRect(x: 0, y: 0, width: 620, height: 877), "an A4 scan at 75 dpi shows 620 x 877 px and hides the extra lines")
    }

    static func visiblePartNeverExceedsImage() {
        let visible = ScannedPage(file: file, resolution: 75, region: TestImage.a4Region).visiblePixels(pixelWidth: 600, pixelHeight: 800)
        expect(visible == CGRect(x: 0, y: 0, width: 600, height: 800), "a scan smaller than its region shows the whole image and no more")
    }
}
