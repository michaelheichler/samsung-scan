import Foundation
import Observation

extension ScanSession {
    // Because T-024 has no document split yet, all pages form one document.
    var documentFacts: DocumentFacts {
        factsTracker.facts
    }

    // So that deleting, reordering, or a late text of the first page reruns the facts.
    func watchDocumentFacts() {
        let firstPages = Observations { @MainActor [weak self] () -> (id: ScannedPage.ID, text: PageText?)? in
            guard let self, let page = pages.first else { return nil }
            return (page.id, pageTexts[page.id])
        }
        Task { [weak self] in
            for await first in firstPages {
                guard let self else { return }
                factsTracker.update(firstPage: first?.id, text: first?.text)
            }
        }
    }
}
