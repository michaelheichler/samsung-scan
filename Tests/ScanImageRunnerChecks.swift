import Foundation

enum ScanImageRunnerChecks {
    static func run() async {
        await runConcurrently([
            emptyFeederWithoutPageThrowsFeederEmpty,
            finishedPageEndsScanNormally,
            badStatusWithoutPageThrowsPageFailed,
            busyScannerIsRetriedUntilItOpens,
            alwaysBusyScannerGivesUpAfterThreeAttempts,
            busyAfterPagesIsNotRetried,
            feederBatchDeliversPagesWhileScanning,
            emptyPageAtExitIsNotDelivered,
        ])
    }

    static func emptyPageAtExitIsNotDelivered() async {
        let outcome = await FakeScan().run("""
            : > "$pages/page001.jpg"
            """)
        expect(outcome.pages.isEmpty, "a 0-byte page at a normal exit is never delivered")
    }

    private static let failedOpen = """
        echo "scanimage: open of device xerox_mfp:tcp 192.0.2.10 failed: Invalid argument" >&2
        exit 1
        """

    static func emptyFeederWithoutPageThrowsFeederEmpty() async {
        let outcome = await FakeScan().run("""
            echo "scanimage: sane_start: Document feeder out of documents" >&2
            exit 7
            """)
        expect(outcome.error as? ScanImageError == .feederEmpty, "an empty feeder before the first page throws feederEmpty")
        expect(outcome.pages.isEmpty, "an empty feeder before the first page delivers no page")
    }

    static func finishedPageEndsScanNormally() async {
        let outcome = await FakeScan().run("""
            printf jpeg > "$pages/page001.jpg"
            echo "Scanned page 1. (scanner status = 5)" >&2
            echo "Batch terminated, 1 page scanned" >&2
            """)
        expect(outcome.pageNames == ["page001.jpg"], "a scan that ends with status 5 delivers its page")
        expect(outcome.error == nil, "a scan that ends with status 5 finishes without error")
    }

    static func badStatusWithoutPageThrowsPageFailed() async {
        let outcome = await FakeScan().run("""
            printf 'Scanning page 1\\nScanned page 1. (scanner status = 9)\\nBatch terminated, 1 page scanned\\n' >&2
            """)
        expect(
            outcome.error as? ScanImageError == .pageFailed(log: ScanImageErrorChecks.failedPageLog),
            "a page that ends with status 9 and leaves no file throws pageFailed")
    }

    static func busyScannerIsRetriedUntilItOpens() async {
        let outcome = await FakeScan().run("""
            opened=$(cat "$state/opened" 2>/dev/null || echo 0)
            echo $((opened + 1)) > "$state/opened"
            if [ "$opened" -lt 2 ]; then
            \(failedOpen)
            fi
            printf jpeg > "$pages/page001.jpg"
            """)
        expect(outcome.pageNames == ["page001.jpg"], "a scanner busy twice delivers the page on the third open")
        expect(outcome.error == nil, "a scanner busy twice finishes without error")
    }

    static func busyAfterPagesIsNotRetried() async {
        let scan = FakeScan()
        let outcome = await scan.run("""
            echo run >> "$state/runs"
            printf jpeg > "$pages/page001.jpg"
            printf jpeg > "$pages/page002.jpg"
            \(failedOpen)
            """)
        expect(outcome.pageNames == ["page001.jpg", "page002.jpg"], "a busy error after two pages keeps both pages")
        expect(outcome.error as? ScanImageError == .scannerBusy(attempts: 1), "a busy error after pages is reported at once")
        expect(scan.lines(of: "runs").count == 1, "a busy error after pages never restarts the batch")
    }

    static func alwaysBusyScannerGivesUpAfterThreeAttempts() async {
        let outcome = await FakeScan().run(failedOpen)
        expect(outcome.error as? ScanImageError == .scannerBusy(attempts: 3), "a scan on a scanner that stays busy gives up after 3 attempts")
    }

    static func feederBatchDeliversPagesWhileScanning() async {
        let scan = FakeScan()
        let (_, stream) = await scan.start("""
            for page in 1 2 3; do
                printf jpeg > "$pages/page00$page.jpg.part"
                sleep 0.1
                mv "$pages/page00$page.jpg.part" "$pages/page00$page.jpg"
            done
            awaitMarker seen
            touch "$state/ended"
            echo "scanimage: sane_start: Document feeder out of documents" >&2
            echo "Batch terminated, 3 pages scanned" >&2
            exit 7
            """)
        let outcome = await ScanOutcome.collect(stream) {
            let ended = scan.exists("ended")
            scan.touch("seen")
            return ended
        }
        expect(outcome.pageNames == ["page001.jpg", "page002.jpg", "page003.jpg"], "three feeder pages arrive in scan order")
        expect(outcome.notes.first == false, "the first feeder page arrives while the feeder still runs")
        expect(outcome.error == nil, "an empty feeder after the last page finishes without error")
    }
}
