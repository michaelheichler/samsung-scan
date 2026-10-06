import Foundation

@MainActor
enum FinishedTextsChecks {
    static func run() async {
        await finishedTextsWaitForRecognizingPages()
        await cancelledWaitThrowsPromptly()
    }

    static func finishedTextsWaitForRecognizingPages() async {
        let unlisted = page("unlisted"), slow = page("slow"), failing = page("failing")
        let outcomes: [URL: Result<PageText, any Error>] = [
            unlisted.file: .success(text(of: unlisted)),
            slow.file: .success(text(of: slow)),
            failing.file: .failure(CocoaError(.fileReadCorruptFile)),
        ]
        let recognition = PageTextRecognition(
            recognize: { file in
                try await Task.sleep(for: .milliseconds(50))
                return try outcomes[file]!.get()
            },
            warmUp: {})
        recognition.start(unlisted)
        recognition.start(slow)
        recognition.start(failing)
        let slowWasRecognizing = recognition.states[slow.id] == .recognizing
        let finished = try? await recognition.finishedTexts(of: [slow, failing])
        expect(
            slowWasRecognizing && finished?[slow.id] == text(of: slow),
            "finished texts wait for a page still recognizing and return its text")
        expect(
            recognition.states[failing.id] == .failed && finished != nil && finished?[failing.id] == nil,
            "finished texts leave out a page whose recognition failed")
        expect(
            recognition.texts[unlisted.id] != nil && finished != nil && finished?[unlisted.id] == nil,
            "finished texts leave out a recognized page that was not asked for")
    }

    static func cancelledWaitThrowsPromptly() async {
        let stuck = page("stuck")
        let recognition = PageTextRecognition(
            recognize: { _ in
                try await Task.sleep(for: .seconds(30))
                return PageText(transcript: "", lines: [])
            },
            warmUp: {})
        recognition.start(stuck)
        let waiting = Task { try await recognition.finishedTexts(of: [stuck]) }
        try? await Task.sleep(for: .milliseconds(50))
        let cancelledAt = ContinuousClock.now
        waiting.cancel()
        let error = await waiting.result.failure
        let delay = ContinuousClock.now - cancelledAt
        let stillRecognizing = recognition.states[stuck.id] == .recognizing
        recognition.cancelAll()
        expect(
            error is CancellationError && stillRecognizing && delay < .seconds(1),
            "cancelling the wait for a page still recognizing throws CancellationError at once")
    }

    private static func page(_ name: String) -> ScannedPage {
        ScannedPage(file: URL(filePath: "/nonexistent/\(name).jpg"), resolution: 300)
    }

    private static func text(of page: ScannedPage) -> PageText {
        PageText(transcript: page.file.lastPathComponent, lines: [])
    }
}
