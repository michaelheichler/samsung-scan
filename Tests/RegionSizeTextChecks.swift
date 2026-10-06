import Foundation

enum RegionSizeTextChecks {
    static func run() {
        usShowsA4InInches()
        metricLocalesShowA4InMillimeters()
        usShowsOddRegionInInches()
        germanyShowsOddRegionInMillimeters()
        millimetersAreWhole()
    }

    private static let a4 = ScanRegion(widthMillimeters: 210, heightMillimeters: 297)
    private static let odd = ScanRegion(widthMillimeters: 120, heightMillimeters: 90)

    private static func text(_ region: ScanRegion, _ locale: String) -> String {
        RegionSizeText.string(for: region, locale: Locale(identifier: locale))
    }

    static func usShowsA4InInches() {
        expect(text(a4, "en_US") == "8.27 × 11.69 in", "the US shows A4 as 8.27 × 11.69 in")
    }

    static func metricLocalesShowA4InMillimeters() {
        expect(text(a4, "de_DE") == "210 × 297 mm", "Germany shows A4 as 210 × 297 mm")
        expect(text(a4, "en_GB") == "210 × 297 mm", "the UK shows A4 in millimeters")
        expect(text(a4, "ja_JP") == "210 × 297 mm", "Japan shows A4 in millimeters")
    }

    static func usShowsOddRegionInInches() {
        expect(text(odd, "en_US") == "4.72 × 3.54 in", "the US shows 120 x 90 mm as 4.72 × 3.54 in")
    }

    static func germanyShowsOddRegionInMillimeters() {
        expect(text(odd, "de_DE") == "120 × 90 mm", "Germany shows 120 x 90 mm as 120 × 90 mm")
    }

    static func millimetersAreWhole() {
        let region = ScanRegion(widthMillimeters: 120.4, heightMillimeters: 90.6)
        expect(text(region, "de_DE") == "120 × 91 mm", "Germany shows 120.4 x 90.6 mm in whole millimeters")
    }
}
