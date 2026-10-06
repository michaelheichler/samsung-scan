import Foundation
import Synchronization

@MainActor
enum BlankPageCheckChecks {
    static func run() async {
        await blankPixelsAndEmptyTextMakeABlankPage()
        await whitespaceTranscriptCountsAsEmpty()
        await recognizedTextKeepsAPageFromBlank()
        await pageTurnsBlankOnlyAfterRecognitionFinishes()
        await nonBlankPixelsKeepAPageFromBlank()
        await blankPagesKeepPageOrder()
        await cancelUnmarksOnlyThatPage()
        await cancelAllUnmarksEveryPage()
        await failingDetectionKeepsAPageFromBlank()
    }

    static func blankPixelsAndEmptyTextMakeABlankPage() async {
        let first = page(1)
        let check = await checked([first], blank: [first])
        let text = await recognized([first], transcripts: [:])
        expect(check.isBlank(first.id, text: text), "a pixel-blank page with an empty transcript is blank")
    }

    static func whitespaceTranscriptCountsAsEmpty() async {
        let first = page(1)
        let check = await checked([first], blank: [first])
        let text = await recognized([first], transcripts: [first.file: " \n\t"])
        expect(check.isBlank(first.id, text: text), "a pixel-blank page whose transcript is only whitespace is blank")
    }

    static func recognizedTextKeepsAPageFromBlank() async {
        let first = page(1)
        let check = await checked([first], blank: [first])
        let text = await recognized([first], transcripts: [first.file: "Seite 2"])
        expect(!check.isBlank(first.id, text: text), "a pixel-blank page with recognized text is not blank")
    }

    static func pageTurnsBlankOnlyAfterRecognitionFinishes() async {
        let first = page(1)
        let check = await checked([first], blank: [first])
        let held = HeldText()
        let text = PageTextRecognition(recognize: { _ in await held.recognize() }, warmUp: {})
        text.start(first)
        _ = await eventually { held.reached }
        let whileRecognizing = check.isBlank(first.id, text: text)
        held.release()
        let blankAfterwards = await eventually { check.isBlank(first.id, text: text) }
        expect(
            !whileRecognizing && blankAfterwards,
            "a pixel-blank page is not blank while recognizing and turns blank once its text comes back empty")
    }

    static func nonBlankPixelsKeepAPageFromBlank() async {
        let first = page(1)
        let check = await checked([first], blank: [])
        let text = await recognized([first], transcripts: [:])
        expect(!check.isBlank(first.id, text: text), "a page whose pixels show content is not blank")
    }

    static func blankPagesKeepPageOrder() async {
        let pages = (1...4).map(page)
        let check = await checked(pages, blank: [pages[1], pages[3]])
        let text = await recognized(pages, transcripts: [:])
        expect(
            check.blankPages(among: pages, text: text) == [pages[1], pages[3]],
            "blank pages among four are exactly pages two and four, so removal keeps pages one and three")
    }

    static func cancelUnmarksOnlyThatPage() async {
        let first = page(1), second = page(2)
        let check = await checked([first, second], blank: [first, second])
        check.cancel(first.id)
        expect(check.blankByPixels == [second.id], "cancel removes the blank mark of that page only")
    }

    static func cancelAllUnmarksEveryPage() async {
        let first = page(1), second = page(2)
        let check = await checked([first, second], blank: [first, second])
        check.cancelAll()
        expect(check.blankByPixels.isEmpty, "cancel all removes every blank mark")
    }

    static func failingDetectionKeepsAPageFromBlank() async {
        let first = page(1)
        let detector = FakeDetector(blank: [first.file], failing: [first.file])
        let check = BlankPageCheck(detect: { try await detector.detect($0) })
        check.start(first)
        await settle(detector, answering: [first])
        let text = await recognized([first], transcripts: [:])
        expect(!check.isBlank(first.id, text: text), "a page whose blank detection throws is not blank")
    }

    private static func page(_ number: Int) -> ScannedPage {
        ScannedPage(file: URL(filePath: "/nonexistent/page\(number).png"), resolution: 300)
    }

    private static func checked(_ pages: [ScannedPage], blank: [ScannedPage]) async -> BlankPageCheck {
        let detector = FakeDetector(blank: Set(blank.map(\.file)))
        let check = BlankPageCheck(detect: { try await detector.detect($0) })
        for page in pages {
            check.start(page)
        }
        await settle(detector, answering: pages)
        return check
    }

    // So that a page marked false has time to land after its detect returns.
    private static func settle(_ detector: FakeDetector, answering pages: [ScannedPage]) async {
        _ = await eventually { detector.answered == Set(pages.map(\.file)) }
        try? await Task.sleep(for: .milliseconds(50))
    }

    private static func recognized(_ pages: [ScannedPage], transcripts: [URL: String]) async -> PageTextRecognition {
        let text = PageTextRecognition(
            recognize: { PageText(transcript: transcripts[$0] ?? "", lines: []) }, warmUp: {})
        for page in pages {
            text.start(page)
        }
        _ = await eventually { pages.allSatisfy { text.states[$0.id] == .done } }
        return text
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

// So that a check knows when every detect call has returned.
private final class FakeDetector: Sendable {
    private let blank: Set<URL>
    private let failing: Set<URL>
    private let finished = Mutex<Set<URL>>([])

    init(blank: Set<URL>, failing: Set<URL> = []) {
        self.blank = blank
        self.failing = failing
    }

    var answered: Set<URL> { finished.withLock { $0 } }

    func detect(_ file: URL) async throws -> Bool {
        defer { finished.withLock { _ = $0.insert(file) } }
        if failing.contains(file) {
            throw CocoaError(.fileReadCorruptFile)
        }
        return blank.contains(file)
    }
}

// So that a check decides when text recognition ends.
private final class HeldText: Sendable {
    private let held = Mutex<CheckedContinuation<Void, Never>?>(nil)

    var reached: Bool { held.withLock { $0 != nil } }

    func recognize() async -> PageText {
        await withCheckedContinuation { continuation in
            held.withLock { $0 = continuation }
        }
        return PageText(transcript: "", lines: [])
    }

    func release() {
        held.withLock { $0.take() }?.resume()
    }
}
