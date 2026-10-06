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

    public private(set) var facts = DocumentFacts.unknown
    @ObservationIgnored private var pageID: ScannedPage.ID?
    @ObservationIgnored private var text: PageText?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private let model: ModelSource

    public init(model: @escaping ModelSource = DocumentFactsTracker.systemModel) {
        self.model = model
    }

    public func update(firstPage id: ScannedPage.ID?, text: PageText?) {
        guard id != pageID || text != self.text else { return }
        pageID = id
        self.text = text
        task?.cancel()
        task = nil
        guard let text else {
            facts = .unknown
            return
        }
        let known = DocumentFactReader.visionFacts(from: text)
        facts = known
        guard let model = model() else { return }
        task = Task {
            let full = await DocumentFactReader.addingModelFacts(to: known, from: text, using: model)
            guard !Task.isCancelled else { return }
            facts = full
        }
    }
}
