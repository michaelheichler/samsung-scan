import Foundation

public struct LetterheadBlock: Equatable, Sendable {
    // Because Vision measures y from the bottom, the top third starts at 2/3.
    static let topEdge = 2.0 / 3.0
    // So that body prose never reads as an address, address lines stay short.
    static let longestAddressLine = 40
    static let fewestAddressLines = 2

    public let sender: String
    public let date: Date

    public init(sender: String, date: Date) {
        self.sender = sender
        self.date = date
    }

    public init?(_ text: PageText) {
        let top = text.lines
            .filter { $0.topLeft.y >= Self.topEdge }
            .sorted { $0.topLeft.y > $1.topLeft.y }
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let sender = top.first,
              let (dateLine, date) = top.lazy.compactMap({ line in Self.date(in: line).map { (line, $0) } }).first
        else { return nil }
        let address = top.filter { $0 != dateLine && $0.count <= Self.longestAddressLine }
        guard address.count >= Self.fewestAddressLines else { return nil }
        self.init(sender: sender, date: date)
    }

    // Because a follow-up page may repeat the letterhead of its first page.
    public func isNew(after previous: LetterheadBlock?) -> Bool {
        previous != self
    }

    private static func date(in line: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        return detector?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))?.date
    }
}
