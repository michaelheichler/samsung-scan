import Foundation

enum ScanCancelChecks {
    static func run() async {
        await runConcurrently([
            cancelStopsScanAndWaitsForExit,
            cancelBeforeLaunchLeavesNoScanimageRunning,
            nextScanWaitsForCancelledScanToExit,
        ])
    }

    static func cancelStopsScanAndWaitsForExit() async {
        let scan = FakeScan()
        let (runner, stream) = await scan.start("""
            trap 'kill $child; sleep 3; touch "$state/exited"; exit 1' TERM
            head -c 54272 /dev/zero > "$pages/page001.jpg.part"
            echo "Scanning page 1" >&2
            sleep 30 > /dev/null 2>&1 &
            child=$!
            touch "$state/ready"
            wait $child
            """)
        let consumer = Task { await ScanOutcome.collect(stream) }
        await scan.awaitMarker("ready")
        let cancelled = ContinuousClock.now
        consumer.cancel()
        let outcome = await consumer.value
        let reaction = ContinuousClock.now - cancelled
        await runner.waitUntilIdle()
        expect(outcome.error is CancellationError, "a cancelled scan ends the page loop with CancellationError")
        expect(reaction < .seconds(1), "a cancelled scan ends the page loop without waiting for scanimage to exit")
        expect(outcome.pages.isEmpty, "a cancelled scan never delivers its unfinished .part page")
        expect(scan.exists("exited"), "waitUntilIdle returns only after scanimage has exited")
    }

    static func cancelBeforeLaunchLeavesNoScanimageRunning() async {
        let scan = FakeScan()
        let (runner, stream) = await scan.start("""
            trap 'kill $child; touch "$state/exited"; exit 1' TERM
            touch "$state/started"
            sleep 30 > /dev/null 2>&1 &
            child=$!
            wait $child
            """)
        let consumer = Task { await ScanOutcome.collect(stream) }
        consumer.cancel()
        let outcome = await consumer.value
        await runner.waitUntilIdle()
        expect(outcome.error is CancellationError, "a scan cancelled at once ends with CancellationError")
        expect(!scan.exists("started") || scan.exists("exited"), "a scan cancelled at once leaves no scanimage running")
    }

    static func nextScanWaitsForCancelledScanToExit() async {
        let scan = FakeScan()
        let runner = scan.runner("""
            if [ ! -e "$state/first-started" ]; then
                trap 'kill $child; sleep 1; touch "$state/first-exited"; exit 1' TERM
                sleep 30 > /dev/null 2>&1 &
                child=$!
                touch "$state/first-started"
                wait $child
            fi
            [ -e "$state/first-exited" ] && touch "$state/second-saw-first-exit"
            printf jpeg > "$pages/page001.jpg"
            """)
        let first = await scan.scan(on: runner)
        let firstConsumer = Task { await ScanOutcome.collect(first) }
        await scan.awaitMarker("first-started")
        firstConsumer.cancel()
        let second = await ScanOutcome.collect(await scan.scan(on: runner))
        expect(second.pageNames == ["page001.jpg"], "a scan after a cancelled scan delivers its page")
        expect(second.error == nil, "a scan after a cancelled scan finishes without error")
        expect(scan.exists("second-saw-first-exit"), "a new scan starts scanimage only after the cancelled one exited")
    }
}
