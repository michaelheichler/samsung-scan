import Foundation

enum ScanProgressReaderChecks {
    static func run() {
        progressSplitAcrossChunksIsRead()
        unknownProgressGivesNoFraction()
        newPageResetsFraction()
        progressAboveHundredIsCapped()
        failedPageLogKeepsEveryByte()
        progressBetweenLinesIsRemoved()
    }

    private static func reader(after chunks: String...) -> ScanProgressReader {
        var reader = ScanProgressReader()
        for chunk in chunks {
            reader.consume(Data(chunk.utf8))
        }
        return reader
    }

    static func progressSplitAcrossChunksIsRead() {
        let halfLine = reader(after: "Progress: 4")
        let fullLine = reader(after: "Progress: 4", "2.3%\r")
        expect(halfLine.fraction == nil, "half a progress line is not read yet")
        expect(fullLine.fraction.map { abs($0 - 0.423) < 0.0005 } == true, "a progress line split over two chunks reads 42.3 %")
    }

    static func unknownProgressGivesNoFraction() {
        expect(reader(after: "Progress: (unknown)\r").fraction == nil, "an unknown progress gives no fraction")
    }

    static func newPageResetsFraction() {
        let reader = reader(after: "Progress: 42.3%\r", "Scanning page 2\n")
        expect(reader.page == 2, "a page line moves progress to that page")
        expect(reader.fraction == nil, "a page line clears the fraction of the last page")
    }

    static func progressAboveHundredIsCapped() {
        expect(reader(after: "Progress: 104.5%\r").fraction == 1, "progress above 100 % counts as complete")
    }

    static func failedPageLogKeepsEveryByte() {
        let log = ScanImageErrorChecks.failedPageLog
        expect(ScanProgressReader.removingProgress(from: log) == log, "removing progress keeps a log without progress byte for byte")
    }

    static func progressBetweenLinesIsRemoved() {
        let log = "Scanning page 1\nProgress: 10.0%\rProgress: 99.9%\rScanned page 1. (scanner status = 9)\n"
        let cleaned = ScanProgressReader.removingProgress(from: log)
        expect(cleaned == "Scanning page 1\nScanned page 1. (scanner status = 9)\n", "progress between log lines is removed")
    }
}
