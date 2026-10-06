import Foundation
import Observation

@MainActor
@Observable
public final class BlankPageCheck {
    public typealias Detect = @concurrent @Sendable (URL) async throws -> Bool

    public private(set) var blankByPixels: Set<ScannedPage.ID> = []
    @ObservationIgnored private var tasks: [ScannedPage.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private let detect: Detect

    public init(detect: @escaping Detect = BlankPageDetector.isBlank(fileAt:)) {
        self.detect = detect
    }

    public func start(_ page: ScannedPage) {
        guard tasks[page.id] == nil, !blankByPixels.contains(page.id) else { return }
        tasks[page.id] = Task(priority: .utility) { [detect] in
            let blank = (try? await detect(page.file)) ?? false
            guard !Task.isCancelled else { return }
            self.finish(page.id, blank: blank)
        }
    }

    public func cancel(_ id: ScannedPage.ID) {
        tasks.removeValue(forKey: id)?.cancel()
        blankByPixels.remove(id)
    }

    public func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks = [:]
        blankByPixels = []
    }

    // So that faint pages stay safe, text or pending recognition rules out blank.
    public func isBlank(_ id: ScannedPage.ID, text: PageTextRecognition) -> Bool {
        guard blankByPixels.contains(id), text.states[id] != .recognizing else { return false }
        return text.texts[id]?.transcript.allSatisfy(\.isWhitespace) ?? true
    }

    public func blankPages(among pages: [ScannedPage], text: PageTextRecognition) -> [ScannedPage] {
        pages.filter { isBlank($0.id, text: text) }
    }

    private func finish(_ id: ScannedPage.ID, blank: Bool) {
        tasks[id] = nil
        if blank {
            blankByPixels.insert(id)
        }
    }
}
