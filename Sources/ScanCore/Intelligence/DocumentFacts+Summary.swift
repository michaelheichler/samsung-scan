import Foundation

extension DocumentFacts {
    // Because all user-facing words are English, the language name is English too.
    private static let languageNames = Locale(identifier: "en")

    public func summary(locale: Locale = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, timeZone: timeZone)
        let parts = [
            heading,
            date.map { $0.formatted(dateStyle) },
            amount.map { $0.value.formatted(.currency(code: $0.currencyCode).locale(locale)) },
            language.flatMap { Self.languageNames.localizedString(forLanguageCode: $0.identifier) },
        ]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }

    private var heading: String? {
        switch (kind, sender) {
        case let (kind?, sender?): "\(kind.name) from \(sender)"
        case let (kind?, nil): kind.name
        case let (nil, sender?): "From \(sender)"
        case (nil, nil): title
        }
    }
}
