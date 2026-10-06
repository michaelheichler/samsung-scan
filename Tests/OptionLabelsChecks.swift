import Foundation

enum OptionLabelsChecks {
    static func run() {
        scannerValuesGetPlainNames()
        unknownValueKeepsScannerText()
        optionNamesBecomeTitles()
        unitsGetSymbols()
        resolutionsFallIntoHints()
        hintsSplitResolutionList()
    }

    static func scannerValuesGetPlainNames() {
        expect(OptionLabels.label(forValue: "ADF") == "Document Feeder", "ADF is shown as Document Feeder")
        expect(OptionLabels.label(forValue: "Lineart") == "Black and White", "Lineart is shown as Black and White")
        expect(OptionLabels.label(forValue: "Gray") == "Grayscale", "Gray is shown as Grayscale")
        expect(OptionLabels.label(forValue: "Flatbed") == "Flatbed", "Flatbed is shown as Flatbed")
    }

    static func unknownValueKeepsScannerText() {
        expect(OptionLabels.label(forValue: "Transparency") == "Transparency", "an unknown value keeps the scanner text")
    }

    static func optionNamesBecomeTitles() {
        expect(OptionLabels.title(forOption: "jpeg") == "JPEG Compression", "jpeg is titled JPEG Compression")
        expect(OptionLabels.title(forOption: "highlight") == "Highlight", "an unknown option name is capitalized")
        expect(OptionLabels.title(forOption: "batch-scan") == "Batch Scan", "a hyphenated option name becomes words")
    }

    static func unitsGetSymbols() {
        expect(OptionLabels.symbol(for: .pixel) == "px", "pixels are shown as px")
        expect(OptionLabels.symbol(for: .microsecond) == "µs", "microseconds are shown as µs")
    }

    private static func hints(_ values: [Int]) -> [ResolutionHint] {
        values.map(ResolutionHint.init(dpi:))
    }

    static func resolutionsFallIntoHints() {
        expect(hints([75, 150, 199]) == [.draft, .draft, .draft], "resolutions below 200 dpi are Draft")
        expect(hints([200, 300, 599]) == [.document, .document, .document], "200 to 599 dpi are Document")
        expect(hints([600, 1200]) == [.photo, .photo], "600 dpi and above are Photo")
    }

    static func hintsSplitResolutionList() {
        let resolutions = [75, 100, 150, 200, 300, 600, 1200]
        expect(ResolutionHint.draft.choices(in: resolutions) == [75, 100, 150], "Draft offers 75, 100 and 150 dpi")
        expect(ResolutionHint.document.choices(in: resolutions) == [200, 300], "Document offers 200 and 300 dpi")
        expect(ResolutionHint.photo.choices(in: resolutions) == [600, 1200], "Photo offers 600 and 1200 dpi")
    }
}
