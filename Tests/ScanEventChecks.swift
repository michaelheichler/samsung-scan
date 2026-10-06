import Foundation

enum ScanEventChecks {
    static func run() async {
        await runConcurrently([
            risingProgressEndsWithPage,
            progressTextDoesNotChangeError,
        ])
    }

    private static func fractions(_ events: [ScanEvent]) -> [Double] {
        events.compactMap { event in
            guard case .progress(_, let fraction) = event else { return nil }
            return fraction
        }
    }

    private static func pageName(_ event: ScanEvent?) -> String? {
        guard case .page(let url)? = event else { return nil }
        return url.lastPathComponent
    }

    static func risingProgressEndsWithPage() async {
        let scan = FakeScan()
        let outcome = await scan.events("""
            printf '%s\\n' "$@" > "$state/arguments"
            printf 'Scanning page 1\\n' >&2
            printf 'Progress: 10.0%%\\r' >&2
            awaitMarker seen-10
            printf 'Progress: 10.0%%\\r' >&2
            sleep 0.7
            for percent in 40 70; do
                printf "Progress: $percent.0%%\\r" >&2
                awaitMarker seen-$percent
            done
            printf jpeg > "$pages/page001.jpg"
            """) { event in
            if case .progress(_, let fraction) = event {
                scan.touch("seen-\(Int((fraction * 100).rounded()))")
            }
        }
        let rising = fractions(outcome.events)
        expect(scan.lines(of: "arguments") == ["--progress"], "a scan asks scanimage for progress")
        expect(rising.count >= 3 && zip(rising, rising.dropFirst()).allSatisfy(<), "progress events rise while the page scans")
        expect(pageName(outcome.events.last) == "page001.jpg", "a scan with progress ends with its page")
        expect(zip(outcome.events, outcome.events.dropFirst()).allSatisfy(!=), "no scan event repeats the one before it")
        expect(outcome.error == nil, "a scan with progress finishes without error")
    }

    static func progressTextDoesNotChangeError() async {
        let outcome = await FakeScan().events("""
            printf 'Progress: 10.0%%\\rProgress: 20.0%%\\rscanimage: sane_read: something odd\\n' >&2
            exit 1
            """)
        let plain = ScanImageError.unknown(log: "scanimage: sane_read: something odd\n")
        expect(outcome.error as? ScanImageError == plain, "progress text before an error leaves the error unchanged")
    }
}
