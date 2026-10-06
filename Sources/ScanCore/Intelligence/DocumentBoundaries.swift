public enum DocumentBoundaries {
    // So that cues decide where they agree and the model only fills gaps.
    public static func cues(for pages: [BoundaryPage], words: PageCountWords) async -> [Int: BoundaryCue] {
        var cues: [Int: BoundaryCue] = [:]
        for index in pages.indices.dropFirst() {
            cues[index] = await cue(at: index, in: pages, words: words)
        }
        return cues
    }

    public static func suggestedSplits(
        for pages: [BoundaryPage], words: PageCountWords, model: (any DocumentLanguageModel)?
    ) async -> [DocumentSplit] {
        let cues = await cues(for: pages, words: words)
        var splits: [DocumentSplit] = []
        for index in cues.keys.sorted() {
            guard let cue = cues[index] else { continue }
            var answer: Bool?
            if case .ask(let question) = cue, let model {
                answer = await question.startsNewDocument(using: model)
            }
            if let reason = resolve(cue, answer: answer) {
                splits.append(DocumentSplit(pageIndex: index, reason: reason))
            }
        }
        return splits
    }

    public static func resolve(_ cue: BoundaryCue, answer: Bool?) -> DocumentSplitReason? {
        switch cue {
        case .split(let reason): reason
        case .join: nil
        case .ask: answer == true ? .languageModel : nil
        }
    }

    private static func cue(at index: Int, in pages: [BoundaryPage], words: PageCountWords) async -> BoundaryCue {
        let page = pages[index]
        guard !page.isBlank, let text = page.text,
              let previousIndex = pages[..<index].lastIndex(where: { !$0.isBlank }) else { return .join }
        let number = words.pageNumber(in: text.transcript)
        if number?.continuesDocument == true { return .join }
        if number?.startsDocument == true { return .split(.firstPageNumber) }
        let previous = pages[previousIndex].text
        let expectsMore = previous.flatMap { words.pageNumber(in: $0.transcript) }?.expectsMorePages ?? false
        let reason = splitReason(text, after: previous, blankBetween: previousIndex < index - 1)
        if let reason, !expectsMore { return .split(reason) }
        guard let previous, !expectsMore || reason != nil,
              !isEmpty(previous), !isEmpty(text) else { return .join }
        return .ask(await PagePairQuestion(between: previous, and: text))
    }

    private static func splitReason(
        _ text: PageText, after previous: PageText?, blankBetween: Bool
    ) -> DocumentSplitReason? {
        if blankBetween { return .blankSeparator }
        guard let letterhead = LetterheadBlock(text),
              letterhead.isNew(after: previous.flatMap(LetterheadBlock.init)) else { return nil }
        return .newLetterhead
    }

    private static func isEmpty(_ text: PageText) -> Bool {
        text.transcript.allSatisfy(\.isWhitespace)
    }
}
