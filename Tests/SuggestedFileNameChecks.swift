import Foundation

enum SuggestedFileNameChecks {
    static func run() {
        germanInvoiceNamesDateKindAndSender()
        englishFactsUseEnglishKindWords()
        languageWithoutTableUsesEnglishWords()
        missingPartsLeaveSingleSpaces()
        nothingKnownFallsBackToScanTime()
        rejectedCharactersBecomeSingleSpaces()
        longSenderIsCutAtWordBoundary()
        singleLongWordIsCutToLimit()
        pageNameUsesSuggestedStem()
    }

    private static let now = try! Date("2026-10-06T10:42:00Z", strategy: .iso8601)
    private static let documentDate = try! Date("2026-03-14T00:00:00Z", strategy: .iso8601)
    private static let german = Locale.LanguageCode("de")
    private static let english = Locale.LanguageCode("en")

    private static func kindNames() -> DocumentKindNames {
        try! DocumentKindNames(contentsOf: PaperCatalog.locateResource(
            named: DocumentKindNames.resourceFileName, bundleResources: nil))
    }

    private static func suggested(_ facts: DocumentFacts) -> ExportFileName {
        ExportFileName(facts: facts, kindNames: kindNames(), now: now, timeZone: .gmt)
    }

    private static func stem(_ facts: DocumentFacts) -> String {
        suggested(facts).stem
    }

    private static func scanTimeStem() -> String {
        ExportFileName(date: now, timeZone: .gmt).stem
    }

    private static func germanInvoice(sender: String? = "Musterfirma", date: Date? = documentDate) -> DocumentFacts {
        DocumentFacts(language: german, kind: .invoice, sender: sender, date: date)
    }

    private static func senderOnly(_ sender: String) -> DocumentFacts {
        DocumentFacts(sender: sender)
    }

    static func germanInvoiceNamesDateKindAndSender() {
        expect(stem(germanInvoice()) == "2026-03-14 Rechnung Musterfirma",
               "a German invoice is named date, Rechnung, sender")
    }

    static func englishFactsUseEnglishKindWords() {
        let invoice = DocumentFacts(language: english, kind: .invoice)
        let letter = DocumentFacts(language: english, kind: .letter, sender: "Acme Ltd", date: documentDate)
        expect(stem(invoice) == "Invoice", "an English invoice with no date and no sender is named Invoice")
        expect(stem(letter) == "2026-03-14 Letter Acme Ltd", "an English letter is named date, Letter, sender")
    }

    static func languageWithoutTableUsesEnglishWords() {
        let englishLetter = stem(DocumentFacts(language: english, kind: .letter, sender: "Acme Ltd"))
        let japanese = DocumentFacts(language: Locale.LanguageCode("ja"), kind: .letter, sender: "Acme Ltd")
        let unknownLanguage = DocumentFacts(kind: .letter, sender: "Acme Ltd")
        expect(stem(japanese) == englishLetter, "a language without kind words falls back to the English word")
        expect(stem(unknownLanguage) == englishLetter, "an unknown language falls back to the English word")
    }

    static func missingPartsLeaveSingleSpaces() {
        let noKind = DocumentFacts(language: german, sender: "Musterfirma", date: documentDate)
        expect(stem(germanInvoice(date: nil)) == "Rechnung Musterfirma", "a missing date leaves no gap")
        expect(stem(noKind) == "2026-03-14 Musterfirma", "a missing kind leaves no gap")
        expect(stem(germanInvoice(sender: nil)) == "2026-03-14 Rechnung", "a missing sender leaves no trailing space")
        expect(stem(germanInvoice(sender: "  Muster   Firma \n")) == "2026-03-14 Rechnung Muster Firma",
               "runs of spaces in the sender shrink to one space")
    }

    static func nothingKnownFallsBackToScanTime() {
        expect(stem(.unknown) == scanTimeStem(), "facts with nothing known give the scan time name")
        expect(stem(senderOnly("///")) == scanTimeStem(), "a sender of only slashes gives the scan time name")
        expect(stem(senderOnly("...")) == scanTimeStem(), "a sender of only dots gives the scan time name")
    }

    static func rejectedCharactersBecomeSingleSpaces() {
        expect(stem(senderOnly("Müller/Schmidt: GmbH")) == "Müller Schmidt GmbH",
               "a slash and a colon in the sender become single spaces")
        expect(stem(senderOnly("Acme\nLtd\tGmbH\u{7}")) == "Acme Ltd GmbH",
               "a newline, a tab and a bell in the sender become single spaces")
        expect(stem(senderOnly(".hidden")) == "hidden", "a name never starts with a dot")
    }

    static func longSenderIsCutAtWordBoundary() {
        let sender = Array(repeating: "Musterfirma", count: 12).joined(separator: " ")
        let firstEightWords = Array(repeating: "Musterfirma", count: 8).joined(separator: " ")
        expect(stem(senderOnly(sender)) == firstEightWords,
               "a 143 character sender keeps the whole words that fit in 100 characters")
    }

    static func singleLongWordIsCutToLimit() {
        let word = String(repeating: "x", count: 150)
        expect(stem(senderOnly(word)) == String(repeating: "x", count: 100),
               "a 150 character word without spaces is cut to 100 characters")
    }

    static func pageNameUsesSuggestedStem() {
        expect(suggested(germanInvoice()).page(2, as: .png) == "2026-03-14 Rechnung Musterfirma - Page 2.png",
               "a page file of a German invoice is named after the suggested name")
    }
}
