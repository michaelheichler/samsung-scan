import Foundation

enum PageCountWordsChecks {
    static func run() {
        let words = try! PageCountWords.bundled()
        footerReadsAsPageNumber("Page 1 of 4", 1, 4, "English footer", words)
        footerReadsAsPageNumber("Seite 2 von 4", 2, 4, "German footer", words)
        footerReadsAsPageNumber("page 3/4", 3, 4, "slash footer", words)
        footerReadsAsPageNumber("Página 1 de 2", 1, 2, "Spanish footer", words)
        footerReadsAsPageNumber("page 2 sur 3", 2, 3, "French footer", words)
        footerReadsAsPageNumber("pagina 1 van 2", 1, 2, "Dutch footer", words)
        footerReadsAsPageNumber("PAGE 2 OF 3", 2, 3, "upper case footer", words)
        footerReadsAsPageNumber("Mit freundlichen Grüßen\nSeite 3 von 3", 3, 3, "footer below the body", words)
        referenceBeyondTheTotalIsNoPageNumber(words)
        textWithoutAFooterHasNoPageNumber(words)
    }

    static func footerReadsAsPageNumber(
        _ transcript: String, _ number: Int, _ total: Int, _ name: String, _ words: PageCountWords
    ) {
        expect(
            words.pageNumber(in: transcript) == PageNumber(number: number, total: total),
            "\(name) reads as page \(number) of \(total)")
    }

    static func referenceBeyondTheTotalIsNoPageNumber(_ words: PageCountWords) {
        expect(words.pageNumber(in: "For details see page 12 of 3.") == nil, "a page 12 of 3 reference is no page number")
    }

    static func textWithoutAFooterHasNoPageNumber(_ words: PageCountWords) {
        expect(
            words.pageNumber(in: "Wir danken für Ihren Auftrag vom 4. Mai 2026.") == nil,
            "a page without a footer has no page number")
    }
}
