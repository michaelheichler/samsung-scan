import Foundation
import Observation

extension ScanSession {
    // So that a new split, a reorder, or a late first page text reruns the facts.
    func watchDocumentFacts() {
        let firstPages = Observations { @MainActor [weak self] () -> (ids: [ScannedPage.ID], texts: [ScannedPage.ID: PageText])? in
            guard let self else { return nil }
            let starts = documentStarts
            return (starts, pageTexts.filter { starts.contains($0.key) })
        }
        Task { [weak self] in
            for await first in firstPages {
                guard let self, let first else { return }
                factsTracker.update(documentStarts: first.ids, texts: first.texts)
            }
        }
    }
}
