import Foundation

@MainActor
enum DocumentBoundaryTrackerChecks {
    static func run() async {
        await cueSplitsShowWithoutAppleIntelligence()
        await lateAnswerForAReplacedStackIsDropped()
        await samePairIsAskedOnceWhenAPageIsAdded()
    }

    private static let words = try! PageCountWords.bundled()

    private static func page(_ transcript: String) -> BoundaryPage {
        BoundaryPage(text: PageText(transcript: transcript, lines: []))
    }

    private static let first = page("Wir bestätigen den Eingang Ihrer Zahlung.")
    private static let second = page("Your parcel will arrive on Monday.")
    private static let third = page("Die Sitzung des Vereins findet im Rathaus statt.")

    static func cueSplitsShowWithoutAppleIntelligence() async {
        let tracker = DocumentBoundaryTracker(model: { nil }, words: words)
        let ids = [UUID(), UUID(), UUID()]
        tracker.update(pageIDs: ids, pages: [first, SampleLetterPages.blank, second])
        let shown = await eventually { tracker.splits.documents(of: ids) == [0..<2, 2..<3] }
        expect(shown, "without Apple Intelligence the tracker shows the split after a blank page")
    }

    static func lateAnswerForAReplacedStackIsDropped() async {
        let model = HeldAnswerModel()
        let tracker = DocumentBoundaryTracker(model: { model }, words: words)
        let (x, y, z) = (UUID(), UUID(), UUID())
        tracker.update(pageIDs: [x, y, z], pages: [first, second, third])
        _ = await eventually { model.prompts.count == 1 }
        let stale = model.prompts.first ?? ""
        tracker.update(pageIDs: [x, z, y], pages: [first, third, second])
        _ = await eventually { model.prompts.count == 2 }
        model.release(stale, with: "yes")
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            tracker.splits.documents(of: [x, z, y]) == [0..<3],
            "a late yes for a pair of the replaced stack does not split the new stack")
        model.settle(with: "no")
    }

    static func samePairIsAskedOnceWhenAPageIsAdded() async {
        let model = FixedAnswerModel(answer: "yes")
        let tracker = DocumentBoundaryTracker(model: { model }, words: words)
        let (x, y, z) = (UUID(), UUID(), UUID())
        tracker.update(pageIDs: [x, y], pages: [first, second])
        _ = await eventually { tracker.splits.documents(of: [x, y]) == [0..<1, 1..<2] }
        tracker.update(pageIDs: [x, y, z], pages: [first, second, third])
        let answered = await eventually { tracker.splits.documents(of: [x, y, z]) == [0..<1, 1..<2, 2..<3] }
        expect(
            answered && model.prompts.count == 2,
            "a page added to the feeder stack asks only about the new pair")
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
