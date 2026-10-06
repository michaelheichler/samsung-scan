import Foundation

enum CapabilityChoicesChecks {
    static func run() {
        listedResolutionsAreOfferedAsListed()
        fineRangeOffersCommonStops()
        coarseRangeOffersStopsOnItsSteps()
        rangeWithoutCommonStopOffersItsEnds()
        inactiveOptionIsNotAdjustable()
        activeHighlightIsAdjustable()
        freeTextOptionIsNotAdjustable()
        listingDescribesQueriedMode()
        listingWithoutModesDescribesAnyMode()
    }

    static func capabilities(_ output: String) -> ScannerCapabilities {
        ScannerCapabilities(options: ScannerOptionParser.parse(output))
    }

    static func activeHighlightListing() -> String {
        fixture("c48x-flatbed").replacing("(in steps of 10) [inactive]", with: "(in steps of 10) [50]")
    }

    private static func resolutionRange(_ range: String) -> ScannerCapabilities {
        capabilities("  Standard:\n    --resolution \(range) [300]\n")
    }

    static func listedResolutionsAreOfferedAsListed() {
        let choices = capabilities(fixture("c48x-flatbed")).resolutionChoices
        expect(choices == [75, 100, 150, 200, 300, 600, 1200], "a listed scanner offers its seven resolutions")
    }

    static func fineRangeOffersCommonStops() {
        let choices = resolutionRange("50..1200dpi (in steps of 1)").resolutionChoices
        expect(choices == [75, 100, 150, 200, 300, 400, 600, 1200], "a 50 to 1200 dpi range offers the common stops")
    }

    static func coarseRangeOffersStopsOnItsSteps() {
        let choices = resolutionRange("100..1000dpi (in steps of 100)").resolutionChoices
        expect(choices == [100, 200, 300, 400, 600], "a range in steps of 100 offers only stops on its steps")
    }

    static func rangeWithoutCommonStopOffersItsEnds() {
        expect(resolutionRange("310..390dpi").resolutionChoices == [310, 390], "a range without a common stop offers its two ends")
    }

    private static func adjustableNames(_ output: String) -> [String] {
        capabilities(output).adjustableExtraOptions.map(\.name)
    }

    static func inactiveOptionIsNotAdjustable() {
        expect(adjustableNames(fixture("c48x-flatbed")) == ["jpeg"], "the inactive highlight is not offered as a setting")
    }

    static func activeHighlightIsAdjustable() {
        expect(adjustableNames(activeHighlightListing()) == ["highlight", "jpeg"], "an active highlight is offered as a setting")
    }

    static func freeTextOptionIsNotAdjustable() {
        let listing = fixture("c48x-flatbed") + "    --ocr-file <string> [/tmp/ocr]\n"
        expect(adjustableNames(listing) == ["jpeg"], "a free text option is not offered as a setting")
    }

    static func listingDescribesQueriedMode() {
        let flatbed = capabilities(fixture("c48x-flatbed"))
        expect(flatbed.describes(mode: "Color"), "a listing queried in Color describes Color")
        expect(!flatbed.describes(mode: "Lineart"), "a listing queried in Color does not describe Lineart")
    }

    static func listingWithoutModesDescribesAnyMode() {
        expect(resolutionRange("50..1200dpi").describes(mode: "Lineart"), "a listing without modes describes any mode")
    }
}
