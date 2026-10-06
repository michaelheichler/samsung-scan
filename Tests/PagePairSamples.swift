import AppKit
import Foundation

// So that the model sees German and English pairs, half of them one document.
enum PagePairSamples {
    static let pairs: [LabeledPagePair] = [
        LabeledPagePair(
            name: "EN letter sentence runs on",
            endOfA: [
                "Thank you for reporting the water damage in your kitchen.",
                "Our assessor visited your home on 2 October 2026.",
                "Based on the photos and the invoice you sent, we will",
            ],
            startOfB: [
                "pay the repair costs of 1,240.00 GBP within ten working days.",
                "If you have any questions, please call us on 0117 496 0000.",
                "Kind regards,",
                "Jane Miller, Claims Team",
            ],
            startsNewDocument: false),
        LabeledPagePair(
            name: "DE letter sentence runs on",
            endOfA: [
                "Ihr Verbrauch lag im letzten Jahr bei 3.420 Kilowattstunden.",
                "Die Nachzahlung beträgt 84,20 EUR und wird mit dem",
            ],
            startOfB: [
                "nächsten Abschlag im April verrechnet.",
                "Ihr neuer monatlicher Abschlag beträgt ab Mai 96,00 EUR.",
                "Mit freundlichen Grüßen",
                "Ihre Stadtwerke Köln",
            ],
            startsNewDocument: false),
        LabeledPagePair(
            name: "DE invoice items carry over",
            endOfA: [
                "Pos. 2 Einrichtung der Texterkennung 420,00 EUR",
                "Pos. 3 Wartung der Scanner im Büro 440,00 EUR",
                "Zwischensumme Seite 1: 860,00 EUR",
            ],
            startOfB: [
                "Übertrag: 860,00 EUR",
                "Pos. 4 Schulung der Mitarbeiter 230,00 EUR",
                "Nettobetrag: 1.090,00 EUR",
                "Gesamtbetrag: 1.297,10 EUR",
            ],
            startsNewDocument: false),
        LabeledPagePair(
            name: "EN contract clause runs on",
            endOfA: [
                "3. Payment. The client pays each invoice within 30 days.",
                "4. Termination. Either party may end this agreement with",
            ],
            startOfB: [
                "three months notice in writing to the address above.",
                "5. Governing law. This agreement follows the laws of England.",
                "Signed for and on behalf of the client",
            ],
            startsNewDocument: false),
        LabeledPagePair(
            name: "EN Kind regards then Dear Sir or Madam",
            endOfA: [
                "Thank you for your patience while we reviewed your claim.",
                "Kind regards,",
                "Tom Baker, Northwind Insurance",
            ],
            startOfB: [
                "Harbor Bank plc",
                "12 Quay Street, Bristol BS1 4DJ",
                "Dear Sir or Madam,",
                "we are writing to tell you about changes to your account terms.",
            ],
            startsNewDocument: true),
        LabeledPagePair(
            name: "EN Best regards ACME then Invoice No. 4471",
            endOfA: [
                "We look forward to working with you next year.",
                "Best regards,",
                "ACME Supplies Ltd.",
            ],
            startOfB: [
                "Invoice No. 4471",
                "Date: 2 October 2026",
                "Office chairs, 4 pieces, 596.00 EUR",
                "Total due: 709.24 EUR",
            ],
            startsNewDocument: true),
        LabeledPagePair(
            name: "DE greeting then tax office notice",
            endOfA: [
                "Die Abrechnung für Ihre Wohnung liegt diesem Schreiben bei.",
                "Mit freundlichen Grüßen",
                "Hausverwaltung Nord",
            ],
            startOfB: [
                "Finanzamt Hamburg-Altona",
                "Bescheid für 2025 über Einkommensteuer",
                "Sehr geehrte Frau Weber,",
                "die Steuer wird wie folgt festgesetzt.",
            ],
            startsNewDocument: true),
        LabeledPagePair(
            name: "DE invoice total then cancellation letter",
            endOfA: [
                "Gesamtbetrag: 129,90 EUR",
                "Bitte überweisen Sie den Betrag bis zum 28.03.2026.",
            ],
            startOfB: [
                "Kündigungsbestätigung",
                "Sehr geehrter Herr Schmidt,",
                "hiermit bestätigen wir die Kündigung Ihres Mobilfunkvertrags",
                "zum 31. Dezember 2026.",
            ],
            startsNewDocument: true),
    ]

    // So that page A ends at the bottom and page B starts at the top, as on paper.
    static func render(_ lines: [String], atBottom: Bool, named name: String, in folder: URL) -> URL {
        let font = NSFont.systemFont(ofSize: 28)
        let top = atBottom ? 120.0 + Double(lines.count) * 60 : 1600.0
        return A4Sheet.jpeg(named: name, in: folder) { _ in
            for (index, line) in lines.enumerated() {
                NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: NSColor.black])
                    .draw(at: NSPoint(x: 120, y: top - Double(index) * 60 + font.descender))
            }
        }
    }
}
