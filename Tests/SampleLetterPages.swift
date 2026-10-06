import CoreGraphics
import Foundation

// So that checks build pages the way Vision reports them, y = 1 at the top.
enum SampleLetterPages {
    static func letterhead(
        sender: String, street: String, town: String, date: String, body: [String], footer: String? = nil
    ) -> PageText {
        page(top: [sender, street, town, date], body: body, footer: footer)
    }

    static func followUp(_ body: [String], footer: String? = nil) -> PageText {
        page(top: [], body: body, footer: footer)
    }

    static func page(top: [String], body: [String], footer: String?) -> PageText {
        let topLines = top.enumerated().map { line($1, y: 0.95 - 0.03 * Double($0)) }
        let bodyLines = body.enumerated().map { line($1, y: 0.6 - 0.04 * Double($0)) }
        let footerLines = footer.map { [line($0, y: 0.05)] } ?? []
        let lines = topLines + bodyLines + footerLines
        return PageText(transcript: lines.map(\.text).joined(separator: "\n"), lines: lines)
    }

    static func line(_ text: String, y: Double) -> RecognizedLine {
        RecognizedLine(
            text: text,
            topLeft: CGPoint(x: 0.1, y: y), topRight: CGPoint(x: 0.9, y: y),
            bottomRight: CGPoint(x: 0.9, y: y - 0.02), bottomLeft: CGPoint(x: 0.1, y: y - 0.02))
    }

    static let blank = BoundaryPage(text: PageText(transcript: "", lines: []), isBlank: true)

    static let threeLetters: [PageText] = [
        letterhead(
            sender: "Stadtwerke Köln", street: "Ringstraße 12", town: "50667 Köln", date: "Köln, 12.03.2026",
            body: ["Sehr geehrte Frau Weber,", "wir passen Ihren monatlichen Abschlag für Strom und Gas an."]),
        followUp([
            "Die neue Höhe richtet sich nach Ihrem Verbrauch der letzten zwölf Monate im Haushalt.",
            "Mit freundlichen Grüßen, Ihre Stadtwerke Köln und das gesamte Team vom Kundenservice",
        ]),
        letterhead(
            sender: "Musterfirma GmbH", street: "Hauptstraße 5", town: "10115 Berlin", date: "Berlin, 6. Oktober 2026",
            body: ["Sehr geehrte Frau Weber,", "anbei erhalten Sie die bestellten Unterlagen zu Ihrem Vertrag."]),
        letterhead(
            sender: "Hausverwaltung Nord", street: "Elbchaussee 40", town: "22763 Hamburg", date: "Hamburg, 14 March 2026",
            body: ["Sehr geehrte Mieterin,", "die Betriebskostenabrechnung für das vergangene Jahr liegt bei."]),
        followUp([
            "Bitte prüfen Sie die Aufstellung der Heizkosten und der Wasserkosten für Ihre Wohnung.",
            "Bei Fragen erreichen Sie uns werktags zwischen neun und zwölf Uhr unter der bekannten Nummer.",
        ]),
    ]

    static let fourPageLetterWithChangingDates: [PageText] = [
        "Berlin, 6. Oktober 2026", "Berlin, 7. Oktober 2026", "Berlin, 8. Oktober 2026", "Berlin, 9. Oktober 2026",
    ].enumerated().map { index, date in
        letterhead(
            sender: "Musterfirma GmbH", street: "Hauptstraße 5", town: "10115 Berlin", date: date,
            body: ["Abschnitt \(index + 1) der Vertragsbedingungen für Ihren Liefervertrag folgt hier."],
            footer: "Page \(index + 1) of 4")
    }
}
