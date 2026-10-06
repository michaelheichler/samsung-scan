import Foundation

enum DocumentFactsSummaryChecks {
    static func run() {
        fullFactsReadAsHeadingDateAmountAndLanguage()
        headingFallsBackFromKindAndSenderToTitle()
        visionFactsAloneReadWithoutAHeading()
        unknownFactsGiveAnEmptySummary()
        dateReadsInTheGivenTimeZone()
        languageNameStaysEnglishUnderAGermanLocale()
    }

    static func fullFactsReadAsHeadingDateAmountAndLanguage() {
        let facts = DocumentFacts(
            language: .german, kind: .invoice, title: "Rechnung Nr. 2026-0412", sender: "Musterfirma GmbH",
            date: noon(day: 14), amount: total)
        expect(
            facts.summary(locale: british, timeZone: berlin) == "Invoice from Musterfirma GmbH, 14 Mar 2026, €129.90, German",
            "full facts read as kind from sender, date, amount, and language")
    }

    static func headingFallsBackFromKindAndSenderToTitle() {
        let cases: [(facts: DocumentFacts, summary: String)] = [
            (DocumentFacts(kind: .letter, title: "Ihre Anfrage"), "Letter"),
            (DocumentFacts(title: "Ihre Anfrage", sender: "Acme Ltd"), "From Acme Ltd"),
            (DocumentFacts(title: "Ihre Anfrage"), "Ihre Anfrage"),
            (DocumentFacts(kind: .other, sender: "Acme Ltd"), "Document from Acme Ltd"),
        ]
        expect(
            cases.map { $0.facts.summary(locale: british, timeZone: berlin) } == cases.map(\.summary),
            "the heading shows kind and sender when known and the title only when both are missing")
    }

    static func visionFactsAloneReadWithoutAHeading() {
        let facts = DocumentFacts(language: .german, date: noon(day: 14), amount: total)
        expect(
            facts.summary(locale: british, timeZone: berlin) == "14 Mar 2026, €129.90, German",
            "vision facts without model facts read as date, amount, and language")
    }

    static func unknownFactsGiveAnEmptySummary() {
        expect(DocumentFacts.unknown.summary(locale: british, timeZone: berlin).isEmpty, "unknown facts give an empty summary")
    }

    static func dateReadsInTheGivenTimeZone() {
        let lateEveningInLondon = DocumentFacts(date: Date(timeIntervalSince1970: 1_773_444_600))
        let summaries = [berlin, TimeZone(identifier: "Europe/London")!].map {
            lateEveningInLondon.summary(locale: british, timeZone: $0)
        }
        expect(summaries == ["14 Mar 2026", "13 Mar 2026"], "the summary date is the calendar day in the given time zone")
    }

    static func languageNameStaysEnglishUnderAGermanLocale() {
        let facts = DocumentFacts(language: .german, date: noon(day: 14))
        expect(
            facts.summary(locale: Locale(identifier: "de_DE"), timeZone: berlin).hasSuffix(", German"),
            "the language name is English even when dates follow a German locale")
    }

    private static let british = Locale(identifier: "en_GB")
    private static let berlin = TimeZone(identifier: "Europe/Berlin")!
    private static let total = DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR")

    private static func noon(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = berlin
        return calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: 12))!
    }
}
