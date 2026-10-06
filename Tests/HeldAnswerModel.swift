import Foundation
import Synchronization

// So that a check decides when the model answers each prompt.
final class HeldAnswerModel: DocumentLanguageModel {
    private struct Calls {
        var prompts: [String] = []
        var held: [String: CheckedContinuation<String, Never>] = [:]
        var settled: String?
    }

    private let calls = Mutex(Calls())

    var prompts: [String] { calls.withLock { $0.prompts } }

    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        let answer = await withCheckedContinuation { continuation in
            let settled = calls.withLock { calls -> String? in
                calls.prompts.append(text)
                if calls.settled == nil { calls.held[text] = continuation }
                return calls.settled
            }
            if let settled { continuation.resume(returning: settled) }
        }
        return Dictionary(uniqueKeysWithValues: fields.map { ($0.name, answer) })
    }

    func release(_ prompt: String, with answer: String) {
        calls.withLock { $0.held.removeValue(forKey: prompt) }?.resume(returning: answer)
    }

    // So that a check ends without a task waiting forever on the fake.
    func settle(with answer: String) {
        let waiting = calls.withLock { calls in
            calls.settled = answer
            defer { calls.held = [:] }
            return Array(calls.held.values)
        }
        for continuation in waiting {
            continuation.resume(returning: answer)
        }
    }
}
