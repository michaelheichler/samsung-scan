import Foundation

@MainActor
enum DocumentBoundaryTrackerChecks {
    static func run() async {
        await cueSplitsShowWithoutAppleIntelligence()
        await lateAnswerForAReplacedStackIsDropped()
        await samePairIsAskedOnceWhenAPageIsAdded()
        await removedBlankPageKeepsItsSplit()
        await pairsLeftToTheModelAreAskedOnceItTurnsOn()
        await askingAgainKeepsConfirmedAndRemovedSplits()
        await askingAgainWithTheModelStillOffKeepsTheSplits()
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
        model.release(stale, with: PagePairQuestion.newDocument)
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            tracker.splits.documents(of: [x, z, y]) == [0..<3],
            "a late new document answer for a pair of the replaced stack does not split the new stack")
        model.settle(with: PagePairQuestion.sameDocument)
    }

    static func samePairIsAskedOnceWhenAPageIsAdded() async {
        let model = FixedAnswerModel(answer: PagePairQuestion.newDocument)
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

    static func removedBlankPageKeepsItsSplit() async {
        let tracker = DocumentBoundaryTracker(model: { nil }, words: words)
        let (x, blank, z) = (UUID(), UUID(), UUID())
        tracker.update(pageIDs: [x, blank, z], pages: [first, SampleLetterPages.blank, second])
        let suggested = await eventually { tracker.splits.suggestion(at: z) == .blankSeparator }
        tracker.confirmSuggestions(for: .blankSeparator)
        tracker.deletePage(blank, from: [x, blank, z])
        tracker.update(pageIDs: [x, z], pages: [first, second])
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            suggested && tracker.splits.documents(of: [x, z], includingSuggested: false) == [0..<1, 1..<2],
            "removing a blank separator page keeps the two documents it divided")
    }

    static func pairsLeftToTheModelAreAskedOnceItTurnsOn() async {
        let source = SwitchedModelSource(model: FixedAnswerModel(answer: PagePairQuestion.newDocument))
        let tracker = DocumentBoundaryTracker(model: source.find, words: words)
        let ids = [UUID(), UUID(), UUID()]
        tracker.update(pageIDs: ids, pages: [first, second, third])
        let cueRunDone = await eventually { source.lookups == 1 && tracker.splits.documents(of: ids) == [0..<3] }
        source.turnOn()
        tracker.askAgainForUnansweredPairs()
        let split = await eventually { tracker.splits.documents(of: ids) == [0..<1, 1..<2, 2..<3] }
        expect(
            cueRunDone && split,
            "pages scanned while Apple Intelligence was off get their model splits when asked again")
    }

    static func askingAgainKeepsConfirmedAndRemovedSplits() async {
        let source = SwitchedModelSource(model: FixedAnswerModel(answer: PagePairQuestion.newDocument))
        let tracker = DocumentBoundaryTracker(model: source.find, words: words)
        let (w, x, y, z) = (UUID(), UUID(), UUID(), UUID())
        tracker.update(pageIDs: [w, x, y, z], pages: [first, second, third, first])
        _ = await eventually { source.lookups == 1 }
        tracker.removeSplit(at: x)
        tracker.confirmSplit(at: y)
        source.turnOn()
        tracker.askAgainForUnansweredPairs()
        let answered = await eventually { tracker.splits.documents(of: [w, x, y, z]) == [0..<2, 2..<3, 3..<4] }
        expect(
            answered && tracker.splits.state(at: x) == .none && tracker.splits.state(at: y) == .confirmed,
            "asking the model again keeps the splits the user removed or confirmed")
    }

    static func askingAgainWithTheModelStillOffKeepsTheSplits() async {
        let model = FixedAnswerModel(answer: PagePairQuestion.newDocument)
        let source = SwitchedModelSource(model: model)
        let tracker = DocumentBoundaryTracker(model: source.find, words: words)
        let (x, y, z) = (UUID(), UUID(), UUID())
        tracker.update(pageIDs: [x, y, z], pages: [first, second, third])
        _ = await eventually { source.lookups == 1 }
        tracker.confirmSplit(at: y)
        tracker.removeSplit(at: z)
        let before = tracker.splits
        tracker.askAgainForUnansweredPairs()
        try? await Task.sleep(for: .milliseconds(50))
        expect(
            model.prompts.isEmpty && tracker.splits == before,
            "asking again while Apple Intelligence is still off asks nothing and keeps the splits")
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
