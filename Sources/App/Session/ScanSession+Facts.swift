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

    // So that pages scanned before Apple Intelligence was ready get model answers.
    func watchModelAvailability() {
        Task { [weak self] in
            for await availability in LanguageModelAvailability.updates where availability.isAvailable {
                self?.askAgainForModelAnswers()
            }
        }
    }

    // Because the availability watch and app activation both lead here.
    func askAgainForModelAnswers() {
        factsTracker.askAgainForMissingModelFacts()
        boundaryTracker.askAgainForUnansweredPairs()
    }
}
