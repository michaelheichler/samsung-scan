import Foundation
import Observation

@MainActor
@Observable
public final class DocumentFactsTracker {
    public typealias ModelSource = @Sendable () -> (any DocumentLanguageModel)?

    // So that a user who turns on Apple Intelligence later gets the model facts.
    public static let systemModel: ModelSource = {
        LanguageModelAvailability.current.isAvailable ? FoundationModelsClient() : nil
    }

    // Because the facts of a document come from its first page, they key by that page.
    public private(set) var factsByFirstPage: [ScannedPage.ID: DocumentFacts] = [:]
    public private(set) var firstPageID: ScannedPage.ID?
    @ObservationIgnored private var texts: [ScannedPage.ID: PageText] = [:]
    @ObservationIgnored private var tasks: [ScannedPage.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private let model: ModelSource

    public init(model: @escaping ModelSource = DocumentFactsTracker.systemModel) {
        self.model = model
    }

    public var facts: DocumentFacts {
        firstPageID.map(facts(ofDocumentStartingAt:)) ?? .unknown
    }

    public func facts(ofDocumentStartingAt id: ScannedPage.ID) -> DocumentFacts {
        factsByFirstPage[id] ?? .unknown
    }

    public func update(firstPage id: ScannedPage.ID?, text: PageText?) {
        guard let id else {
            update(documentStarts: [], texts: [:])
            return
        }
        update(documentStarts: [id], texts: text.map { [id: $0] } ?? [:])
    }

    public func update(documentStarts: [ScannedPage.ID], texts: [ScannedPage.ID: PageText]) {
        firstPageID = documentStarts.first
        for id in Set(self.texts.keys).subtracting(documentStarts) {
            forget(id)
        }
        for id in documentStarts {
            update(id, text: texts[id])
        }
    }

    private func update(_ id: ScannedPage.ID, text: PageText?) {
        guard text != texts[id] else { return }
        forget(id)
        guard let text else { return }
        texts[id] = text
        let known = DocumentFactReader.visionFacts(from: text)
        factsByFirstPage[id] = known
        guard let model = model() else { return }
        tasks[id] = Task {
            let full = await DocumentFactReader.addingModelFacts(to: known, from: text, using: model)
            guard !Task.isCancelled else { return }
            factsByFirstPage[id] = full
            tasks[id] = nil
        }
    }

    private func forget(_ id: ScannedPage.ID) {
        tasks.removeValue(forKey: id)?.cancel()
        texts[id] = nil
        factsByFirstPage[id] = nil
    }
}
