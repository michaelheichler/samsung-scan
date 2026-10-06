import Foundation

enum OnDeviceModelFactsChecks {
    static func run() async {
        guard LanguageModelAvailability.current.isAvailable else {
            print("skip  on-device model facts: Apple Intelligence is not available")
            return
        }
        await germanInvoiceIsReadAsAnInvoiceWithASender()
    }

    static func germanInvoiceIsReadAsAnInvoiceWithASender() async {
        let facts = try? await DocumentFactReader.addingModelFacts(
            to: .unknown, from: invoice, using: FoundationModelsClient())
        expect(
            facts?.kind == .invoice && facts?.sender?.contains("Musterfirma") == true,
            "the on-device model reads a clear German invoice as an invoice from the company in its letterhead")
    }

    static let invoice = PageText(
        transcript: """
            Musterfirma GmbH
            Hauptstraße 5, 10115 Berlin
            Frau Anna Weber
            Lindenweg 3, 50667 Köln
            Rechnung Nr. 2026-0412
            Rechnungsdatum: 14.03.2026
            Pos. 1 Wartung der Scanner 109,16 EUR
            Nettobetrag: 109,16 EUR
            Umsatzsteuer 19 %: 20,74 EUR
            Gesamtbetrag: 129,90 EUR
            Bitte überweisen Sie den Betrag bis zum 28.03.2026.
            """,
        lines: [])
}
