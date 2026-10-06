import AppKit
import Foundation

// Because skew needs at least 5 long lines, this letter holds 12 of them.
enum LetterPage {
    static let fontSize = 28.0

    static let lines = [
        "Rechnung Nr. 2026-0412 vom 30. September 2026",
        "Invoice for consulting services in September",
        "Leistungszeitraum: 1. bis 30. September 2026",
        "Beratung und Konzeption der neuen Scan Ablage",
        "Workshop with the team about document intake",
        "Einrichtung der Texterkennung auf allen Geräten",
        "Review of the archive structure and file names",
        "Nettobetrag: 1.090,00 EUR zuzüglich Umsatzsteuer",
        "Umsatzsteuer 19 Prozent: 207,10 EUR auf den Betrag",
        "Gesamtbetrag: 1.297,10 EUR fällig in vierzehn Tagen",
        "Bitte überweisen Sie den Betrag auf unser Konto",
        "Thank you for your business and kind regards",
    ]

    static func jpeg(in folder: URL) -> URL {
        let font = NSFont.systemFont(ofSize: fontSize)
        return A4Sheet.jpeg(named: "letter", in: folder) { _ in
            for (index, line) in lines.enumerated() {
                let baseline = 1580.0 - Double(index) * 110
                NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: NSColor.black])
                    .draw(at: NSPoint(x: 120, y: baseline + font.descender))
            }
        }
    }
}
