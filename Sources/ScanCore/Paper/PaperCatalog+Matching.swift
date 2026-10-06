import Foundation

extension PaperCatalog {
    // Because the scanner rounds lines up, a 75 dpi A4 page measures 213 x 302 mm.
    public static let matchToleranceMillimeters = 6.0

    public func size(matchingWidth width: Double, height: Double) -> PaperSize? {
        let short = min(width, height)
        let long = max(width, height)
        func deviation(_ paper: PaperSize) -> (short: Double, long: Double) {
            let paperShort = min(paper.widthMillimeters, paper.heightMillimeters)
            let paperLong = max(paper.widthMillimeters, paper.heightMillimeters)
            return (abs(short - paperShort), abs(long - paperLong))
        }
        return sizes
            .filter {
                let gap = deviation($0)
                return gap.short <= Self.matchToleranceMillimeters && gap.long <= Self.matchToleranceMillimeters
            }
            .min { deviation($0).short + deviation($0).long < deviation($1).short + deviation($1).long }
    }
}
