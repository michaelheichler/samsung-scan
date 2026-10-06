import Foundation

// Because splits follow page IDs, a reorder keeps each split on its page.
public struct DocumentSplits: Equatable, Sendable {
    public private(set) var suggested: [ScannedPage.ID: DocumentSplitReason] = [:]
    public private(set) var confirmed: Set<ScannedPage.ID> = []
    // So that a split the user removed never comes back with the next suggestion run.
    public private(set) var removed: Set<ScannedPage.ID> = []

    public init() {}

    public mutating func suggest(_ splits: [ScannedPage.ID: DocumentSplitReason]) {
        suggested = splits
    }

    public mutating func confirm(at id: ScannedPage.ID) {
        confirmed.insert(id)
        removed.remove(id)
    }

    public mutating func remove(at id: ScannedPage.ID) {
        confirmed.remove(id)
        removed.insert(id)
    }

    // So that a blank page removal keeps the split its blank page created.
    public mutating func confirmSuggestions(for reason: DocumentSplitReason) {
        for (id, suggestedReason) in suggested where suggestedReason == reason && suggestion(at: id) != nil {
            confirm(at: id)
        }
    }

    // So that a confirmed split survives when the user deletes its page.
    public mutating func deletePage(_ id: ScannedPage.ID, from pageIDs: [ScannedPage.ID]) {
        removed.remove(id)
        guard confirmed.remove(id) != nil, let index = pageIDs.firstIndex(of: id), index > 0,
              pageIDs.indices.contains(index + 1) else { return }
        confirm(at: pageIDs[index + 1])
    }

    public mutating func clear() {
        self = DocumentSplits()
    }

    public func suggestion(at id: ScannedPage.ID) -> DocumentSplitReason? {
        guard !confirmed.contains(id), !removed.contains(id) else { return nil }
        return suggested[id]
    }

    public func state(at id: ScannedPage.ID) -> DocumentSplitState {
        if confirmed.contains(id) { return .confirmed }
        return suggestion(at: id).map(DocumentSplitState.suggested) ?? .none
    }

    public func startsDocument(_ id: ScannedPage.ID, includingSuggested: Bool) -> Bool {
        confirmed.contains(id) || (includingSuggested && suggestion(at: id) != nil)
    }

    public func openSuggestions(in pageIDs: [ScannedPage.ID]) -> [ScannedPage.ID] {
        pageIDs.dropFirst().filter { suggestion(at: $0) != nil }
    }

    public func documents(of pageIDs: [ScannedPage.ID], includingSuggested: Bool = true) -> [Range<Int>] {
        guard !pageIDs.isEmpty else { return [] }
        let starts = [0] + pageIDs.indices.dropFirst().filter {
            startsDocument(pageIDs[$0], includingSuggested: includingSuggested)
        }
        return zip(starts, starts.dropFirst() + [pageIDs.count]).map { $0..<$1 }
    }
}
