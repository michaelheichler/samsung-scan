import Foundation

enum ExtraOptionValueChecks {
    static func run() {
        unsetFlagReadsScannerDefault()
        clearedFlagIsStoredAsNo()
        unsetNumberReadsCurrentValue()
        numberWithoutCurrentValueReadsRangeMinimum()
        wholeNumberIsStoredWithoutFraction()
        fractionIsStoredWithPoint()
        unsetChoiceReadsCurrentValue()
        choiceWithoutAnyValueReadsEmpty()
        storedChoiceWinsOverCurrentValue()
    }

    private static func request() -> ScanRequest {
        ScanRequest(
            deviceName: "xerox_mfp:tcp 192.0.2.10", source: "Flatbed", mode: "Color", resolution: 300,
            region: ScanRegion(widthMillimeters: 210, heightMillimeters: 297))
    }

    private static func option(_ name: String, in listing: String = fixture("c48x-flatbed")) -> ScannerOption {
        ScannerOptionParser.parse(listing).first { $0.name == name }!
    }

    static func unsetFlagReadsScannerDefault() {
        expect(request()[flag: option("jpeg")], "an unset jpeg flag reads the scanner default yes")
    }

    static func clearedFlagIsStoredAsNo() {
        var request = request()
        request[flag: option("jpeg")] = false
        expect(request.extraOptionValues["jpeg"] == "no", "turning jpeg off stores no")
        expect(!request[flag: option("jpeg")], "turning jpeg off reads back as off")
    }

    static func unsetNumberReadsCurrentValue() {
        let highlight = option("highlight", in: CapabilityChoicesChecks.activeHighlightListing())
        expect(request()[number: highlight] == 50, "an unset highlight reads the scanner value 50")
    }

    static func numberWithoutCurrentValueReadsRangeMinimum() {
        expect(request()[number: option("highlight")] == 30, "a highlight without a scanner value reads the range minimum 30")
    }

    static func wholeNumberIsStoredWithoutFraction() {
        var request = request()
        request[number: option("highlight")] = 60
        expect(request.extraOptionValues["highlight"] == "60", "a highlight of 60 is stored as 60")
    }

    static func fractionIsStoredWithPoint() {
        var request = request()
        request[number: option("highlight")] = 50.5
        expect(request.extraOptionValues["highlight"] == "50.5", "a highlight of 50.5 is stored with a decimal point")
    }

    static func unsetChoiceReadsCurrentValue() {
        expect(request()[choice: option("source")] == "Flatbed", "an unset choice reads the scanner value")
    }

    static func choiceWithoutAnyValueReadsEmpty() {
        expect(request()[choice: option("highlight")] == "", "a choice without any value reads empty")
    }

    static func storedChoiceWinsOverCurrentValue() {
        var request = request()
        request[choice: option("source")] = "ADF"
        expect(request.extraOptionValues["source"] == "ADF", "a chosen value is stored under the option name")
        expect(request[choice: option("source")] == "ADF", "a chosen value wins over the scanner value")
    }
}
