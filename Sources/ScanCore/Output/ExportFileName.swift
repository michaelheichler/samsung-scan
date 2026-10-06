import Foundation

public struct ExportFileName: Hashable, Sendable {
    public let stem: String

    public init(date: Date, timeZone: TimeZone = .current) {
        let style = Date.VerbatimFormatStyle(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)).\(minute: .twoDigits)",
            timeZone: timeZone,
            calendar: Calendar(identifier: .gregorian))
        stem = "Scan \(date.formatted(style))"
    }

    public func document(as format: ExportFormat) -> String {
        "\(stem).\(format.fileExtension)"
    }

    public func page(_ number: Int, as format: ExportFormat) -> String {
        "\(stem) - Page \(number).\(format.fileExtension)"
    }
}
