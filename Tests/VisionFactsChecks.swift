import AppKit
import Foundation

enum VisionFactsChecks {
    static func run() async {
        guard await VisionProbe.canReadText(for: "Vision facts") else { return }
        let folder = TemporaryFolder.make()
        await germanInvoiceGivesGermanItsInvoiceDateAndItsTotal(in: folder)
        await englishLetterGivesEnglishItsLetterDateAndNoAmount(in: folder)
        await cafeReceiptGivesItsTotal(in: folder)
    }

    static func germanInvoiceGivesGermanItsInvoiceDateAndItsTotal(in folder: URL) async {
        let page = DrawnPage.render(DrawnPage.germanInvoice, named: "invoice", in: folder)
        let facts = await visionFacts(of: page)
        expect(facts?.language == .german, "a recognized German invoice reads as German")
        expect(
            day(of: facts?.date) == DateComponents(year: 2026, month: 3, day: 14),
            "a recognized invoice dates to its invoice date")
        expect(
            facts?.amount == DocumentAmount(value: Decimal(string: "129.90")!, currencyCode: "EUR"),
            "a recognized invoice amounts to its gross total, not its net or tax line")
    }

    static func englishLetterGivesEnglishItsLetterDateAndNoAmount(in folder: URL) async {
        let page = DrawnPage.render(DrawnPage.englishLetter, named: "letter", in: folder)
        let facts = await visionFacts(of: page)
        expect(facts?.language == .english, "a recognized English letter reads as English")
        expect(
            day(of: facts?.date) == DateComponents(year: 2026, month: 10, day: 6),
            "a recognized letter dates to its own date, not the date it quotes")
        expect(facts != nil && facts?.amount == nil, "a recognized letter without money has no amount")
    }

    static func cafeReceiptGivesItsTotal(in folder: URL) async {
        let page = DrawnPage.render(DrawnPage.cafeReceipt, named: "receipt", in: folder)
        let facts = await visionFacts(of: page)
        expect(
            facts?.amount == DocumentAmount(value: Decimal(string: "6.30")!, currencyCode: "EUR"),
            "a recognized receipt amounts to its sum, not one of its items")
    }

    private static func visionFacts(of page: URL) async -> DocumentFacts? {
        (try? await TextRecognizer.recognize(fileAt: page)).map(DocumentFactReader.visionFacts(from:))
    }

    private static func day(of date: Date?) -> DateComponents? {
        date.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
    }
}

private enum DrawnPage {
    static let width = 1240.0
    static let height = 1754.0
    static let fontSize = 26.0
    static let lineGap = 70.0
    static let left = 100.0
    static let top = 1600.0

    static let germanInvoice = [
        "Musterfirma GmbH, Hauptstraße 5, 10115 Berlin",
        "Rechnung Nr. 2026-0412",
        "Rechnungsdatum: 14.03.2026",
        "Nettobetrag: 109,16 EUR",
        "MwSt. 19 %: 20,74 EUR",
        "Gesamtbetrag: 129,90 EUR",
        "Bitte überweisen Sie den Betrag bis zum 28.03.2026.",
    ]

    static let englishLetter = [
        "Acme Ltd, 12 High Street, London",
        "6 October 2026",
        "Dear Mr Smith,",
        "thank you for your letter of 2 September.",
        "We have reviewed your request and will reply within two weeks.",
        "Yours sincerely,",
        "Jane Doe",
    ]

    static let cafeReceipt = [
        "Café Sonnenschein",
        "Marktplatz 3, 80331 München",
        "05.10.2026 09:42",
        "Cappuccino 3,80 EUR",
        "Croissant 2,50 EUR",
        "Summe: 6,30 EUR",
        "Vielen Dank für Ihren Besuch",
    ]

    static func render(_ lines: [String], named name: String, in folder: URL) -> URL {
        let font = NSFont.systemFont(ofSize: fontSize)
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height), bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        for (row, line) in lines.enumerated() {
            NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: NSColor.black])
                .draw(at: NSPoint(x: left, y: top - Double(row) * lineGap))
        }
        NSGraphicsContext.restoreGraphicsState()
        let url = folder.appending(path: "\(name).png")
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
        return url
    }
}
