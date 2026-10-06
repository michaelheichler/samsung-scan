import Foundation
import Synchronization

// So that one fake stands for a model that answers every field alike or fails.
final class FixedAnswerModel: DocumentLanguageModel {
    struct Failure: Error {}

    private let answer: String?
    private let asked = Mutex<[String]>([])

    init(answer: String?) {
        self.answer = answer
    }

    var prompts: [String] { asked.withLock { $0 } }

    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        asked.withLock { $0.append(text) }
        guard let answer else { throw Failure() }
        return Dictionary(uniqueKeysWithValues: fields.map { ($0.name, answer) })
    }
}
