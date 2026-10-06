import Foundation

enum ScanProgressChecks {
    static func run() {
        noEstimateBelowFivePercent()
        tenPercentInTwelveSecondsLeavesHundredEight()
        olderPageIsIgnored()
        deliveredPageStartsNextPage()
        recordEndsStall()
        deliveredPageEndsStall()
    }

    private static let start = ContinuousClock.now

    private static func progress(_ records: [(page: Int, fraction: Double, seconds: Int)]) -> ScanProgress {
        var progress = ScanProgress()
        for record in records {
            progress.record(page: record.page, fraction: record.fraction, at: start.advanced(by: .seconds(record.seconds)))
        }
        return progress
    }

    static func noEstimateBelowFivePercent() {
        let early = progress([(1, 0, 0), (1, 0.04, 12)])
        expect(early.remaining == nil, "a page below 5 % has no time estimate")
    }

    static func tenPercentInTwelveSecondsLeavesHundredEight() {
        let remaining = progress([(1, 0, 0), (1, 0.10, 12)]).remaining
        let isClose = remaining.map { $0 > .milliseconds(107_999) && $0 < .milliseconds(108_001) } ?? false
        expect(isClose, "10 % of a page in 12 s leaves an estimate of 108 s")
    }

    static func olderPageIsIgnored() {
        let progress = progress([(2, 0.5, 0), (1, 0.9, 1)])
        expect(progress.page == 2 && progress.fraction == 0.5, "a record for an older page is ignored")
    }

    static func deliveredPageStartsNextPage() {
        var progress = progress([(1, 0, 0), (1, 0.5, 10)])
        progress.pageDelivered()
        expect(progress.page == 2 && progress.pagesSoFar == 1, "a delivered page moves progress to the next page")
        expect(progress.fraction == nil && progress.remaining == nil, "a delivered page clears the fraction and the estimate")
    }

    static func recordEndsStall() {
        var progress = ScanProgress()
        progress.isStalled = true
        progress.record(page: 1, fraction: 0.2, at: start)
        expect(!progress.isStalled, "new progress ends a stall")
    }

    static func deliveredPageEndsStall() {
        var progress = ScanProgress()
        progress.isStalled = true
        progress.pageDelivered()
        expect(!progress.isStalled, "a delivered page ends a stall")
    }
}
