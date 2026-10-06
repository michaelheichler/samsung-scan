import Foundation

extension ScanSession {
    // Because the angle comes from the page text, Straighten waits for it.
    func canStraighten(_ page: ScannedPage) -> Bool {
        guard canCorrect(page), textState(of: page) == .done, let text = pageTexts[page.id],
              let size = page.pixelSize else { return false }
        return PageSkew.degrees(of: text, pixelWidth: size.width, pixelHeight: size.height) != nil
    }

    func canTrim(_ page: ScannedPage) -> Bool {
        canCorrect(page) && !corrections.trimmedIDs.contains(page.id)
    }

    func canUndoChanges(_ page: ScannedPage) -> Bool {
        canCorrect(page) && corrections.originals[page.id] != nil
    }

    func straighten(_ page: ScannedPage) {
        guard canStraighten(page), let text = pageTexts[page.id] else { return }
        Task {
            await finishCorrection("Straighten", of: page) { try await self.corrections.straightened(page, text: text) }
        }
    }

    func trimToContent(_ page: ScannedPage) {
        guard canTrim(page) else { return }
        Task {
            await finishCorrection("Trim to Content", of: page) { try await self.corrections.trimmed(page) }
        }
    }

    func undoChanges(_ page: ScannedPage) {
        guard canUndoChanges(page), let original = corrections.restoreOriginal(of: page.id) else { return }
        replace(page, with: original)
    }

    private func canCorrect(_ page: ScannedPage) -> Bool {
        canEditPages && !corrections.runningIDs.contains(page.id)
    }

    // So that a page deleted during the work stays deleted, its result is dropped.
    private func finishCorrection(
        _ action: String, of page: ScannedPage, work: () async throws -> ScannedPage?
    ) async {
        outcome = nil
        do {
            guard let corrected = try await work() else {
                outcome = .pageUnchanged(action: action)
                return
            }
            guard pages.contains(page) else { return corrections.forget(page.id) }
            replace(page, with: corrected)
        } catch {
            outcome = .correctionFailed(message: Self.failureMessage(for: error))
        }
    }
}
