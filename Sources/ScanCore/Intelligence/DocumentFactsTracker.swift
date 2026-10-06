import Foundation
import Observation

@MainActor
@Observable
public final class DocumentFactsTracker {
    public typealias ModelSource = @Sendable () -> (any DocumentLanguageModel)?

    // Because Apple Intelligence can turn on later, each ask checks it again.
    public static let systemModel: ModelSource = {
        LanguageModelAvailability.current.isAvailable ? FoundationModelsClient() : nil
    }

    // So that a busy model gets a second chance without a retry storm.
    public static let retryDelays: [Duration] = [.seconds(2), .seconds(10)]

    // Because the facts of a document come from its first page, they key by that page.
    public private(set) var factsByFirstPage: [ScannedPage.ID: DocumentFacts] = [:]
    public private(set) var firstPageID: ScannedPage.ID?
    @ObservationIgnored private var texts: [ScannedPage.ID: PageText] = [:]
    @ObservationIgnored private var tasks: [ScannedPage.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var answeredIDs: Set<ScannedPage.ID> = []
    @ObservationIgnored private let model: ModelSource
    @ObservationIgnored private let retryDelays: [Duration]

    public init(
        model: @escaping ModelSource = DocumentFactsTracker.systemModel,
        retryDelays: [Duration] = DocumentFactsTracker.retryDelays
    ) {
        self.model = model
        self.retryDelays = retryDelays
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

    // So that documents without model facts get them once Apple Intelligence is on.
    public func askAgainForMissingModelFacts() {
        for id in texts.keys {
            askModel(about: id)
        }
    }

    private func update(_ id: ScannedPage.ID, text: PageText?) {
        guard text != texts[id] else { return }
        forget(id)
        guard let text else { return }
        texts[id] = text
        factsByFirstPage[id] = DocumentFactReader.visionFacts(from: text)
        askModel(about: id)
    }

    private func askModel(about id: ScannedPage.ID) {
        guard tasks[id] == nil, !answeredIDs.contains(id), let text = texts[id], let model = model() else { return }
        let known = DocumentFactReader.visionFacts(from: text)
        tasks[id] = Task { [retryDelays] in
            defer { if !Task.isCancelled { tasks[id] = nil } }
            for delay in [.zero] + retryDelays {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
                guard let full = try? await DocumentFactReader.addingModelFacts(to: known, from: text, using: model)
                else { continue }
                guard !Task.isCancelled else { return }
                factsByFirstPage[id] = full
                answeredIDs.insert(id)
                return
            }
        }
    }

    private func forget(_ id: ScannedPage.ID) {
        tasks.removeValue(forKey: id)?.cancel()
        texts[id] = nil
        answeredIDs.remove(id)
        factsByFirstPage[id] = nil
    }
}
