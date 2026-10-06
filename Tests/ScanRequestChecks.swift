import Foundation

enum ScanRequestChecks {
    static func run() {
        a4FlatbedRequestBuildsScanimageArguments()
        unlimitedPagesHaveNoBatchCount()
        listedResolutionSnapsToNearestOffered()
        oversizedWidthIsCutToGlass()
        offsetRegionKeepsInsideGlass()
        unknownSourceAndModeFallBackToScannerDefaults()
        feederListingFallsBackToFeeder()
        onlyActiveExtraOptionsSurviveValidation()
        singleLetterOptionIsPassedAsPair()
        millimetersPrintWithPointAndNoTrailingZeros()
        previewScansWholeGlassAtLowestResolution()
        rangeResolutionSnapsToSteps()
        stepAboveRangeMaximumSnapsDown()
        previewOnRangeScannerUsesRangeMinimum()
        previewSwitchToColorDropsExtras()
        previewInColorKeepsExtras()
        previewWithoutColorKeepsModeAndExtras()
    }

    private static let folder = URL(filePath: "/tmp/scan")

    private static func flatbed() -> ScannerCapabilities {
        ScannerCapabilities(options: ScannerOptionParser.parse(fixture("c48x-flatbed")))
    }

    private static func a4Region() -> ScanRegion {
        let a4 = PaperCatalogChecks.bundledCatalog()?.sizes.first { $0.id == "iso-a4" }
        return a4.map(ScanRegion.init(paper:)) ?? ScanRegion(widthMillimeters: 0, heightMillimeters: 0)
    }

    private static func request(
        source: String = "Flatbed",
        mode: String = "Color",
        resolution: Int = 300,
        region: ScanRegion? = nil,
        extraOptionValues: [String: String] = [:],
        pageLimit: Int? = 1
    ) -> ScanRequest {
        ScanRequest(
            deviceName: "xerox_mfp:tcp 192.0.2.10",
            source: source,
            mode: mode,
            resolution: resolution,
            region: region ?? a4Region(),
            extraOptionValues: extraOptionValues,
            pageLimit: pageLimit)
    }

    private static func argument(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    private static func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.0005
    }

    static func a4FlatbedRequestBuildsScanimageArguments() {
        let arguments = request().arguments(batchFolder: folder)
        expect(arguments.contains("--device-name=xerox_mfp:tcp 192.0.2.10"), "a request names its device")
        expect(arguments.contains("--source=Flatbed"), "a flatbed request selects the glass")
        expect(arguments.contains("--mode=Color"), "a request passes its color mode")
        expect(argument(after: "-x", in: arguments) == "210", "A4 request scans 210 mm wide")
        expect(argument(after: "-y", in: arguments) == "297", "A4 request scans 297 mm high")
        expect(arguments.contains("--batch-count=1"), "a one page request stops after one page")
        expect(arguments.contains("--format=jpeg"), "a scan asks scanimage for JPEG")
        expect(arguments.contains("--batch=/tmp/scan/page%03d.jpg"), "a scan writes numbered JPEG pages")
    }

    static func unlimitedPagesHaveNoBatchCount() {
        let arguments = request(pageLimit: nil).arguments(batchFolder: folder)
        expect(!arguments.contains { $0.hasPrefix("--batch-count") }, "a request without page limit has no batch count")
    }

    private static func checkResolution(_ requested: Int, becomes expected: Int, on capabilities: ScannerCapabilities) {
        let validated = request(resolution: requested).validated(against: capabilities)
        expect(validated.resolution == expected, "\(requested) dpi becomes \(expected) dpi")
    }

    static func listedResolutionSnapsToNearestOffered() {
        checkResolution(250, becomes: 300, on: flatbed())
        checkResolution(5000, becomes: 1200, on: flatbed())
        checkResolution(10, becomes: 75, on: flatbed())
    }

    static func oversizedWidthIsCutToGlass() {
        let wide = ScanRegion(widthMillimeters: 400, heightMillimeters: 297.18)
        let validated = request(region: wide).validated(against: flatbed())
        expect(isClose(validated.region.widthMillimeters, 216.069), "a 400 mm width is cut to the 216.069 mm glass")
        expect(
            argument(after: "-x", in: validated.arguments(batchFolder: folder)) == "216.069",
            "the cut width reaches scanimage as 216.069")
    }

    static func offsetRegionKeepsInsideGlass() {
        let offset = ScanRegion(leftMillimeters: 100, widthMillimeters: 200, heightMillimeters: 100)
        let validated = request(region: offset).validated(against: flatbed())
        expect(isClose(validated.region.leftMillimeters, 100), "a region 100 mm from the left keeps its offset")
        expect(isClose(validated.region.widthMillimeters, 116.069), "a region 100 mm from the left is 116.069 mm wide at most")
    }

    static func unknownSourceAndModeFallBackToScannerDefaults() {
        let validated = request(source: "Tray", mode: "Sepia").validated(against: flatbed())
        expect(validated.source == "Flatbed", "an unknown source falls back to the scanner default Flatbed")
        expect(validated.mode == "Color", "an unknown mode falls back to the scanner default Color")
    }

    static func feederListingFallsBackToFeeder() {
        let feeder = ScannerCapabilities(options: ScannerOptionParser.parse(fixture("c48x-adf")))
        let validated = request(source: "Tray").validated(against: feeder)
        expect(validated.source == "ADF", "an unknown source falls back to ADF when ADF is the current source")
    }

    static func onlyActiveExtraOptionsSurviveValidation() {
        let values = ["jpeg": "no", "highlight": "50", "bogus": "1", "resolution": "75"]
        let validated = request(extraOptionValues: values).validated(against: flatbed())
        expect(validated.extraOptionValues == ["jpeg": "no"], "only the active extra option jpeg survives validation")
        expect(validated.arguments(batchFolder: folder).last == "--jpeg=no", "the jpeg choice reaches scanimage as --jpeg=no")
    }

    static func singleLetterOptionIsPassedAsPair() {
        let arguments = request(extraOptionValues: ["q": "5"]).arguments(batchFolder: folder)
        expect(argument(after: "-q", in: arguments) == "5", "a one letter option is passed as -q 5")
    }

    static func millimetersPrintWithPointAndNoTrailingZeros() {
        let region = ScanRegion(leftMillimeters: 10.5, widthMillimeters: 205.5, heightMillimeters: 210.0)
        let arguments = request(region: region).arguments(batchFolder: folder)
        expect(argument(after: "-l", in: arguments) == "10.5", "a 10.5 mm offset prints as 10.5")
        expect(argument(after: "-x", in: arguments) == "205.5", "a 205.5 mm width prints as 205.5")
        expect(argument(after: "-y", in: arguments) == "210", "a 210.0 mm height prints as 210")
        expect(!arguments.contains { $0.contains(",") }, "no argument holds a decimal comma")
    }

    static func previewScansWholeGlassAtLowestResolution() {
        let preview = request(mode: "Gray", pageLimit: nil).preview(for: flatbed())
        expect(preview.resolution == 75, "preview uses the lowest resolution 75 dpi")
        expect(preview.mode == "Color", "preview scans in color")
        expect(
            preview.region == ScanRegion(widthMillimeters: 216.069, heightMillimeters: 297.18),
            "preview covers the whole glass from the top left corner")
        expect(preview.pageLimit == 1, "preview scans one page")
    }

    private static func rangeScanner(upTo maximum: Int) -> ScannerCapabilities {
        ScannerCapabilities(options: ScannerOptionParser.parse(
            "  Standard:\n    --resolution 50..\(maximum)dpi (in steps of 25) [300]\n        Resolution.\n"))
    }

    static func rangeResolutionSnapsToSteps() {
        let ranged = rangeScanner(upTo: 1200)
        checkResolution(10, becomes: 50, on: ranged)
        checkResolution(260, becomes: 250, on: ranged)
        checkResolution(263, becomes: 275, on: ranged)
        checkResolution(1199, becomes: 1200, on: ranged)
        checkResolution(5000, becomes: 1200, on: ranged)
    }

    static func stepAboveRangeMaximumSnapsDown() {
        checkResolution(1215, becomes: 1200, on: rangeScanner(upTo: 1215))
    }

    private static func highlightScanner(modes: String = "Lineart|Halftone|Gray|Color [Color]") -> ScannerCapabilities {
        let listing = CapabilityChoicesChecks.activeHighlightListing()
            .replacing("--mode Lineart|Halftone|Gray|Color [Color]", with: "--mode \(modes)")
        return CapabilityChoicesChecks.capabilities(listing)
    }

    static func previewSwitchToColorDropsExtras() {
        let preview = request(mode: "Gray", extraOptionValues: ["highlight": "60"]).preview(for: highlightScanner())
        expect(preview.mode == "Color", "preview of a gray scan switches to color")
        expect(preview.extraOptionValues.isEmpty, "preview drops extra options chosen for another mode")
        expect(!preview.arguments(batchFolder: folder).contains("--highlight=60"), "preview never sends an extra option of another mode")
    }

    static func previewInColorKeepsExtras() {
        let preview = request(mode: "Color", extraOptionValues: ["highlight": "60"]).preview(for: highlightScanner())
        expect(preview.extraOptionValues == ["highlight": "60"], "preview of a color scan keeps its active extra options")
    }

    static func previewWithoutColorKeepsModeAndExtras() {
        let grayOnly = highlightScanner(modes: "Gray|Lineart [Gray]")
        let preview = request(mode: "Gray", extraOptionValues: ["highlight": "60"]).preview(for: grayOnly)
        expect(preview.mode == "Gray", "preview on a scanner without color keeps the mode")
        expect(preview.extraOptionValues == ["highlight": "60"], "preview on a scanner without color keeps the extra options")
    }

    static func previewOnRangeScannerUsesRangeMinimum() {
        let preview = request().preview(for: rangeScanner(upTo: 1200))
        expect(preview.resolution == 50, "preview on a range scanner uses the range minimum 50 dpi")
    }
}
