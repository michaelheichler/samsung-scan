import Foundation

enum ScanImageErrorChecks {
    static func run() {
        coverOpenGivesEnglishHint()
        deviceInputOutputErrorIsConnectionFailure()
        unknownTextIsQuotedInMessage()
        scanimagePrefixesAreStrippedFromQuote()
        failedOpenMeansScannerBusy()
        deviceBusyMeansScannerBusy()
        jammedFeederIsPaperJam()
        feederOutOfDocumentsIsEmptyFeeder()
        badPageStatusIsFailedPage()
        silentFailureSaysNoReason()
        repeatedBusyMessageCountsAttempts()
        singleBusyAttemptMessageCountsNothing()
        missingScanimageMessageNamesInstallCommand()
    }

    static let failedPageLog =
        "Scanning page 1\nScanned page 1. (scanner status = 9)\nBatch terminated, 1 page scanned\n"

    private static func mapped(_ text: String) -> ScanImageError {
        ScanImageError.fromScanImageErrors(text)
    }

    static func coverOpenGivesEnglishHint() {
        let error = mapped("scanimage: sane_start: Scanner cover is open\n")
        expect(error == .coverOpen, "an open cover is recognized")
        expect(error.message == "The scanner cover is open. Close it and try again.", "an open cover gives an English hint")
    }

    static func deviceInputOutputErrorIsConnectionFailure() {
        expect(mapped("scanimage: sane_start: Error during device I/O\n") == .ioError, "a device I/O error is a connection failure")
    }

    static func unknownTextIsQuotedInMessage() {
        let error = mapped("something odd")
        expect(error == .unknown(log: "something odd"), "unknown scanner text stays unknown")
        expect(error.message == "The scanner reported an error: something odd", "unknown scanner text is quoted in the message")
    }

    static func scanimagePrefixesAreStrippedFromQuote() {
        let log = "scanimage: sane_start: something odd\n"
        let error = mapped(log)
        expect(error == .unknown(log: log), "prefixed unknown scanner text stays unknown")
        expect(error.message == "The scanner reported an error: something odd", "the quote drops the scanimage and sane_start prefixes")
    }

    static func failedOpenMeansScannerBusy() {
        let error = mapped("scanimage: open of device xerox_mfp:tcp 192.0.2.10 failed: Invalid argument\n")
        expect(error == .scannerBusy(attempts: 1), "a failed open means the scanner is busy")
        expect(!error.message.contains("setting"), "a failed open does not blame the settings")
    }

    static func deviceBusyMeansScannerBusy() {
        expect(mapped("scanimage: sane_start: Device busy\n") == .scannerBusy(attempts: 1), "device busy means the scanner is busy")
    }

    static func jammedFeederIsPaperJam() {
        expect(mapped("scanimage: sane_start: Document feeder jammed\n") == .paperJam, "a jammed feeder is a paper jam")
    }

    static func feederOutOfDocumentsIsEmptyFeeder() {
        let error = mapped("scanimage: sane_start: Document feeder out of documents\n")
        expect(error == .feederEmpty, "a feeder out of documents is an empty feeder")
    }

    static func badPageStatusIsFailedPage() {
        let error = mapped(failedPageLog)
        expect(error == .pageFailed(log: failedPageLog), "a page that ends with status 9 is a failed page")
        expect(!error.message.contains("Batch terminated"), "the failed page message hides the scanimage log")
    }

    static func silentFailureSaysNoReason() {
        let error = mapped("")
        expect(error == .unknown(log: ""), "a failure without text is unknown")
        expect(error.message == "The scanner returned no page and gave no reason.", "a failure without text says no reason was given")
    }

    static func repeatedBusyMessageCountsAttempts() {
        expect(ScanImageError.scannerBusy(attempts: 3).message.contains("tried 3 times"), "the busy message counts the attempts")
    }

    static func singleBusyAttemptMessageCountsNothing() {
        expect(!ScanImageError.scannerBusy(attempts: 1).message.contains("tried"), "the busy message after one attempt names no retry count")
    }

    static func missingScanimageMessageNamesInstallCommand() {
        let message = ScanImageError.scanImageMissing.message
        expect(message.contains("brew install sane-backends"), "the missing scanimage message names the install command")
    }
}
