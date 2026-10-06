import Foundation

enum PaperMatchingChecks {
    static func run() {
        scannedA4MatchesA4()
        scannedA5MatchesA5()
        landscapeMatchesSamePaper()
        sixMillimetersOffStillMatches()
        moreThanSixMillimetersOffMatchesNothing()
        closerPaperWins()
    }

    private static func matchedID(_ width: Double, _ height: Double) -> String? {
        PaperCatalogChecks.bundledCatalog()?.size(matchingWidth: width, height: height)?.id
    }

    static func scannedA4MatchesA4() {
        expect(matchedID(210.0, 301.8) == "iso-a4", "a 75 dpi A4 scan of 210 x 301.8 mm is A4")
    }

    static func scannedA5MatchesA5() {
        expect(matchedID(148.0, 213.4) == "iso-a5", "a scan of 148 x 213.4 mm is A5")
    }

    static func landscapeMatchesSamePaper() {
        expect(matchedID(301.8, 210.0) == "iso-a4", "a landscape scan of 301.8 x 210 mm is A4")
    }

    static func sixMillimetersOffStillMatches() {
        expect(matchedID(210, 303) == "iso-a4", "a page 6 mm longer than A4 is still A4")
    }

    static func moreThanSixMillimetersOffMatchesNothing() {
        expect(matchedID(210, 303.1) == nil, "a page 6.1 mm longer than A4 matches no paper")
    }

    static func closerPaperWins() {
        expect(matchedID(178, 252) == "iso-b5", "178 x 252 mm is closer to B5 than to JIS B5")
        expect(matchedID(180, 255) == "jis-b5", "180 x 255 mm is closer to JIS B5 than to B5")
    }
}
