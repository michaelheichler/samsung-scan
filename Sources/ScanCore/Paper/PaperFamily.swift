import Foundation

public enum PaperFamily: String, CaseIterable, Codable, Comparable, Sendable {
    case isoA = "iso-a"
    case isoB = "iso-b"
    case jisB = "jis-b"
    case us
    case other

    public static func < (lhs: PaperFamily, rhs: PaperFamily) -> Bool {
        lhs.sortRank < rhs.sortRank
    }

    private var sortRank: Int {
        Self.allCases.firstIndex(of: self) ?? Self.allCases.count
    }
}
