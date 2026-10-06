import Foundation
import Observation

extension ScanSession {
    var documentSplits: DocumentSplits {
        boundaryTracker.splits
    }

    // So that T-025 can show suggested dividers before the user confirms them.
    var documents: [Range<Int>] {
        documentSplits.documents(of: pageIDs)
    }

    var documentStarts: [ScannedPage.ID] {
        documents.map { pages[$0.lowerBound].id }
    }

    func facts(of document: Range<Int>) -> DocumentFacts {
        guard pages.indices.contains(document.lowerBound) else { return .unknown }
        return factsTracker.facts(ofDocumentStartingAt: pages[document.lowerBound].id)
    }

    func confirmSplit(at page: ScannedPage) {
        boundaryTracker.confirmSplit(at: page.id)
    }

    func removeSplit(at page: ScannedPage) {
        boundaryTracker.removeSplit(at: page.id)
    }

    // So that new, moved, deleted, or newly read pages rerun the suggestions.
    func watchDocumentBoundaries() {
        let stacks = Observations { @MainActor [weak self] () -> (ids: [ScannedPage.ID], pages: [BoundaryPage])? in
            guard let self else { return nil }
            return (pageIDs, pages.map { BoundaryPage(text: pageTexts[$0.id], isBlank: isBlank($0)) })
        }
        Task { [weak self] in
            for await stack in stacks {
                guard let self, let stack else { return }
                boundaryTracker.update(pageIDs: stack.ids, pages: stack.pages)
            }
        }
    }
}
