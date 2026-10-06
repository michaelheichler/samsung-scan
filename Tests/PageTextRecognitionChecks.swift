import Foundation
import Synchronization

@MainActor
enum PageTextRecognitionChecks {
    static func run() async {
        await startReturnsWhileTheRecognizerIsBusy()
        await finishedPageGetsItsText()
        await failingPageGetsNoText()
        await cancelRemovesThePageAtOnce()
        await lateTextOfCancelledPageIsDropped()
        await pagesRunOneAtATimeInStartOrder()
        await warmUpRunsBeforeTheFirstPage()
        await cancelAllClearsEveryPage()
    }

    static func startReturnsWhileTheRecognizerIsBusy() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1), second = page(2)
        recognition.start(first)
        let busy = await eventually { work.reached == [.page(first.file)] }
        recognition.start(second)
        expect(
            busy && recognition.states == [first.id: .recognizing, second.id: .recognizing] && recognition.texts.isEmpty,
            "start marks pages as recognizing and returns while the recognizer is still busy")
    }

    static func finishedPageGetsItsText() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1)
        recognition.start(first)
        _ = await eventually { work.reached == [.page(first.file)] }
        work.release(.page(first.file), with: .success(invoice))
        let done = await eventually { recognition.states[first.id] == .done }
        expect(done && recognition.texts == [first.id: invoice], "a recognized page is done and holds its text")
    }

    static func failingPageGetsNoText() async {
        let recognition = PageTextRecognition(recognize: { _ in throw CocoaError(.fileReadCorruptFile) }, warmUp: {})
        let first = page(1)
        recognition.start(first)
        let failed = await eventually { recognition.states[first.id] == .failed }
        expect(failed && recognition.texts.isEmpty, "a page whose recognition throws is failed and holds no text")
    }

    static func cancelRemovesThePageAtOnce() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1)
        recognition.start(first)
        _ = await eventually { work.reached == [.page(first.file)] }
        recognition.cancel(first.id)
        expect(
            recognition.states.isEmpty && recognition.texts.isEmpty,
            "cancel during recognition removes the page state at once")
    }

    static func lateTextOfCancelledPageIsDropped() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1), second = page(2)
        recognition.start(first)
        _ = await eventually { work.reached == [.page(first.file)] }
        recognition.cancel(first.id)
        recognition.start(second)
        work.release(.page(first.file), with: .success(invoice))
        let firstEnded = await eventually { work.reached == [.page(first.file), .page(second.file)] }
        expect(
            firstEnded && recognition.states[first.id] == nil && recognition.texts[first.id] == nil,
            "text that arrives after cancel leaves no entry for the cancelled page")
    }

    static func pagesRunOneAtATimeInStartOrder() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1), second = page(2)
        recognition.start(first)
        recognition.start(second)
        _ = await eventually { !work.reached.isEmpty }
        try? await Task.sleep(for: .milliseconds(50))
        let whileFirstHeld = work.reached
        work.release(.page(first.file), with: .success(invoice))
        let secondReached = await eventually { work.reached.count == 2 }
        expect(
            whileFirstHeld == [.page(first.file)] && secondReached
                && work.reached == [.page(first.file), .page(second.file)],
            "the second page reaches the recognizer only after the first page finishes")
    }

    static func warmUpRunsBeforeTheFirstPage() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1)
        recognition.warmUp()
        recognition.start(first)
        _ = await eventually { !work.reached.isEmpty }
        try? await Task.sleep(for: .milliseconds(50))
        let whileWarmingUp = work.reached
        work.release(.warmUp)
        let pageReached = await eventually { work.reached.count == 2 }
        expect(
            whileWarmingUp == [.warmUp] && pageReached && work.reached == [.warmUp, .page(first.file)],
            "a page started after warm-up reaches the recognizer only when warm-up finishes")
    }

    static func cancelAllClearsEveryPage() async {
        let work = HeldWork()
        let recognition = recognition(using: work)
        let first = page(1), second = page(2), third = page(3)
        recognition.start(first)
        _ = await eventually { work.reached == [.page(first.file)] }
        work.release(.page(first.file), with: .success(invoice))
        _ = await eventually { recognition.states[first.id] == .done }
        recognition.start(second)
        recognition.start(third)
        recognition.cancelAll()
        expect(
            recognition.states.isEmpty && recognition.texts.isEmpty,
            "cancel all clears done, running, and queued pages")
    }

    private static let invoice = PageText(
        transcript: "Rechnung Nr. 2026-0412",
        lines: [RecognizedLine(
            text: "Rechnung Nr. 2026-0412", topLeft: CGPoint(x: 0.1, y: 0.9), topRight: CGPoint(x: 0.5, y: 0.9),
            bottomRight: CGPoint(x: 0.5, y: 0.88), bottomLeft: CGPoint(x: 0.1, y: 0.88))])

    private static func page(_ number: Int) -> ScannedPage {
        ScannedPage(file: URL(filePath: "/nonexistent/page\(number).png"), resolution: 300)
    }

    private static func recognition(using work: HeldWork) -> PageTextRecognition {
        PageTextRecognition(recognize: { try await work.recognize($0) }, warmUp: { await work.warmUp() })
    }

    private static func eventually(_ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition() {
            guard ContinuousClock.now < deadline else { return false }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}

private enum HeldCall: Hashable, Sendable {
    case warmUp
    case page(URL)
}

// So that a check decides when each call ends.
private final class HeldWork: Sendable {
    private struct Calls {
        var reached: [HeldCall] = []
        var held: [HeldCall: CheckedContinuation<Result<PageText, any Error>, Never>] = [:]
    }

    private let calls = Mutex(Calls())

    var reached: [HeldCall] { calls.withLock { $0.reached } }

    func recognize(_ file: URL) async throws -> PageText {
        try await hold(.page(file)).get()
    }

    func warmUp() async {
        _ = await hold(.warmUp)
    }

    func release(_ call: HeldCall, with result: Result<PageText, any Error> = .success(PageText(transcript: "", lines: []))) {
        calls.withLock { $0.held.removeValue(forKey: call) }?.resume(returning: result)
    }

    private func hold(_ call: HeldCall) async -> Result<PageText, any Error> {
        await withCheckedContinuation { continuation in
            calls.withLock {
                $0.reached.append(call)
                $0.held[call] = continuation
            }
        }
    }
}
