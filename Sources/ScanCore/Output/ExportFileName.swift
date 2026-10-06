import Foundation

public struct ExportFileName: Hashable, Sendable {
    public let stem: String

    public init(date: Date, timeZone: TimeZone = .current) {
        let style = Self.style(
            "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)).\(minute: .twoDigits)",
            timeZone)
        stem = "Scan \(date.formatted(style))"
    }

    // So that files sort by the date of the document in Finder.
    public init(facts: DocumentFacts, kindNames: DocumentKindNames, now: Date = .now, timeZone: TimeZone = .current) {
        let day = facts.date.map {
            $0.formatted(Self.style("\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)", timeZone))
        }
        let kind = facts.kind.flatMap { kindNames.word(for: $0, language: facts.language) }
        let suggested = FileNameStem.joining([day, kind, facts.sender].compactMap { $0 })
        stem = suggested.isEmpty ? ExportFileName(date: now, timeZone: timeZone).stem : suggested
    }

    private static func style(_ format: Date.FormatString, _ timeZone: TimeZone) -> Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(format: format, timeZone: timeZone, calendar: Calendar(identifier: .gregorian))
    }

    public func document(as format: ExportFormat) -> String {
        "\(stem).\(format.fileExtension)"
    }

    public func page(_ number: Int, as format: ExportFormat) -> String {
        "\(stem) - Page \(number).\(format.fileExtension)"
    }
}
