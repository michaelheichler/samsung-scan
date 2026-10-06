import Foundation

extension PageTextRecognition {
    // Because a page finishes within seconds, polling stays cheap and cancellable.
    private static let pollInterval = Duration.milliseconds(100)

    public func finishedTexts(of pages: [ScannedPage]) async throws -> [ScannedPage.ID: PageText] {
        while pages.contains(where: { states[$0.id] == .recognizing }) {
            try await Task.sleep(for: Self.pollInterval)
        }
        try Task.checkCancellation()
        let pairs = pages.compactMap { page in text(of: page).map { (page.id, $0) } }
        return Dictionary(pairs, uniquingKeysWith: { first, _ in first })
    }
}
