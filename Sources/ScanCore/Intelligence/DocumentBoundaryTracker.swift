import Foundation
import Observation

@MainActor
@Observable
public final class DocumentBoundaryTracker {
    public private(set) var splits = DocumentSplits()
    @ObservationIgnored private var pageIDs: [ScannedPage.ID] = []
    @ObservationIgnored private var pages: [BoundaryPage] = []
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var isSuggesting = false
    // So that a new page in a feeder run does not ask about every old pair again.
    @ObservationIgnored private var answers: [PagePairQuestion: Bool] = [:]
    @ObservationIgnored private let model: DocumentFactsTracker.ModelSource
    @ObservationIgnored private let words: PageCountWords

    public init(
        model: @escaping DocumentFactsTracker.ModelSource = DocumentFactsTracker.systemModel,
        words: PageCountWords = (try? .bundled()) ?? PageCountWords(languages: [:])
    ) {
        self.model = model
        self.words = words
    }

    public func update(pageIDs: [ScannedPage.ID], pages: [BoundaryPage]) {
        guard pageIDs != self.pageIDs || pages != self.pages else { return }
        self.pageIDs = pageIDs
        self.pages = pages
        startSuggesting()
    }

    // So that pairs decided by cues alone get a model answer once it is ready.
    public func askAgainForUnansweredPairs() {
        guard !isSuggesting, !pageIDs.isEmpty, model() != nil else { return }
        startSuggesting()
    }

    private func startSuggesting() {
        task?.cancel()
        isSuggesting = true
        task = Task { [pageIDs, pages] in
            await suggest(pageIDs: pageIDs, pages: pages)
            if !Task.isCancelled { isSuggesting = false }
        }
    }

    public func confirmSplit(at id: ScannedPage.ID) {
        splits.confirm(at: id)
    }

    public func removeSplit(at id: ScannedPage.ID) {
        splits.remove(at: id)
    }

    public func confirmSuggestions(for reason: DocumentSplitReason) {
        splits.confirmSuggestions(for: reason)
    }

    public func deletePage(_ id: ScannedPage.ID, from pageIDs: [ScannedPage.ID]) {
        splits.deletePage(id, from: pageIDs)
    }

    public func clear() {
        task?.cancel()
        task = nil
        isSuggesting = false
        pageIDs = []
        pages = []
        splits.clear()
    }

    // So that cue splits show at once and each model answer joins as it comes.
    private func suggest(pageIDs: [ScannedPage.ID], pages: [BoundaryPage]) async {
        let cues = await DocumentBoundaries.cues(for: pages, words: words)
        guard !Task.isCancelled else { return }
        var suggested: [ScannedPage.ID: DocumentSplitReason] = [:]
        var questions: [(index: Int, question: PagePairQuestion)] = []
        for index in cues.keys.sorted() {
            guard let cue = cues[index] else { continue }
            if case .ask(let question) = cue {
                questions.append((index, question))
            }
            suggested[pageIDs[index]] = DocumentBoundaries.resolve(cue, answer: cachedAnswer(to: cue))
        }
        splits.suggest(suggested)
        guard let model = model() else { return }
        for (index, question) in questions where answers[question] == nil {
            let answer = await question.startsNewDocument(using: model)
            guard !Task.isCancelled else { return }
            answers[question] = answer
            suggested[pageIDs[index]] = DocumentBoundaries.resolve(.ask(question), answer: answer)
            splits.suggest(suggested)
        }
    }

    private func cachedAnswer(to cue: BoundaryCue) -> Bool? {
        guard case .ask(let question) = cue else { return nil }
        return answers[question]
    }
}
