import Foundation

enum CapabilitiesChecks {
    static func run() {
        flatbedListingGivesChoicesAndGlassArea()
        feederListingGivesLongerAreaFromRangeMaximum()
        highlightIsInactivePercentRange()
        jpegIsAdvancedBooleanSetToYes()
        onlyNonStandardOptionsAreExtras()
        garbageLinesAddNoOption()
        unreachableScannerGivesNoChoices()
        geometryWithoutNumericMaximumGivesNoArea()
    }

    private static func capabilities(_ output: String) -> ScannerCapabilities {
        ScannerCapabilities(options: ScannerOptionParser.parse(output))
    }

    private static func flatbedOption(_ name: String) -> ScannerOption? {
        ScannerOptionParser.parse(fixture("c48x-flatbed")).first { $0.name == name }
    }

    static func flatbedListingGivesChoicesAndGlassArea() {
        let flatbed = capabilities(fixture("c48x-flatbed"))
        expect(flatbed.resolutions == [75, 100, 150, 200, 300, 600, 1200], "flatbed offers the seven C48x resolutions")
        expect(flatbed.modes == ["Lineart", "Halftone", "Gray", "Color"], "flatbed offers the four C48x modes")
        expect(flatbed.sources == ["Flatbed", "ADF", "Auto"], "flatbed lists all three sources")
        expect(
            flatbed.scanArea == ScanArea(widthMillimeters: 216.069, heightMillimeters: 297.18),
            "flatbed scan area is the glass size 216.069 x 297.18 mm")
    }

    static func feederListingGivesLongerAreaFromRangeMaximum() {
        let feeder = capabilities(fixture("c48x-adf"))
        expect(
            feeder.scanArea == ScanArea(widthMillimeters: 216.069, heightMillimeters: 355.6),
            "feeder scan area uses the range maximum 355.6 mm, not the current 297.18")
    }

    static func highlightIsInactivePercentRange() {
        let highlight = flatbedOption("highlight")
        expect(highlight?.value == .range(min: 30, max: 70, step: 10), "highlight is a range 30 to 70 in steps of 10")
        expect(highlight?.unit == .percent, "highlight is measured in percent")
        expect(highlight?.isInactive == true, "highlight is marked inactive")
    }

    static func jpegIsAdvancedBooleanSetToYes() {
        let jpeg = flatbedOption("jpeg")
        expect(jpeg?.value == .boolean, "jpeg is a yes or no option")
        expect(jpeg?.isAdvanced == true, "jpeg is marked advanced")
        expect(jpeg?.isInactive == false, "jpeg is active")
        expect(jpeg?.currentValue == "yes", "jpeg is currently on")
    }

    static func onlyNonStandardOptionsAreExtras() {
        let flatbed = capabilities(fixture("c48x-flatbed"))
        expect(flatbed.extraOptions.map(\.name) == ["highlight", "jpeg"], "extra options are exactly highlight and jpeg")
    }

    static func garbageLinesAddNoOption() {
        let output = """
            Output format is not set, using pnm as a default.
            scanimage: open of device xerox_mfp:tcp 192.0.2.10 failed: Invalid argument
                -
                --
                - [inactive]
                    stray text at description depth
                --mode Gray|Color [Gray]
            """
        expect(ScannerOptionParser.parse(output).map(\.name) == ["mode"], "garbage lines around an option add no option")
    }

    static func unreachableScannerGivesNoChoices() {
        let unreachable = capabilities(
            "scanimage: open of device xerox_mfp:tcp 192.0.2.10 failed: Invalid argument\n")
        expect(unreachable.sources.isEmpty, "an unreachable scanner offers no sources")
        expect(unreachable.resolutions.isEmpty, "an unreachable scanner offers no resolutions")
        expect(unreachable.scanArea == nil, "an unreachable scanner reports no scan area")
    }

    static func geometryWithoutNumericMaximumGivesNoArea() {
        let truncated = capabilities("""
              Geometry:
                -x 0..mm (in steps of 1) [0]
                -y 0..297.18mm (in steps of 1) [297.18]
            """)
        expect(truncated.scanArea == nil, "a width without a numeric maximum gives no scan area")
    }
}
