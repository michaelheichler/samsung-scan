import Foundation
import Synchronization

// So that a check sees a busy model fail a set number of calls and then answer.
final class FlakyModel: DocumentLanguageModel {
    struct Busy: Error {}

    private let failures: Int
    private let answer: [String: String]
    private let calls = Mutex(0)

    init(failing failures: Int, then answer: [String: String]) {
        self.failures = failures
        self.answer = answer
    }

    var callCount: Int { calls.withLock { $0 } }

    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        let call = calls.withLock { count in
            count += 1
            return count
        }
        guard call > failures else { throw Busy() }
        return answer
    }
}
