import Synchronization

final class PendingResolve: Sendable {
    private struct State {
        var waiter: CheckedContinuation<DiscoveredScanner?, Never>?
        var result: DiscoveredScanner?
        var isFinished = false
    }

    let name: String
    private let state = Mutex(State())

    init(name: String) {
        self.name = name
    }

    func finish(_ result: DiscoveredScanner?) {
        let waiter = state.withLock { state -> CheckedContinuation<DiscoveredScanner?, Never>? in
            guard !state.isFinished else { return nil }
            state.isFinished = true
            state.result = result
            defer { state.waiter = nil }
            return state.waiter
        }
        waiter?.resume(returning: result)
    }

    func value() async -> DiscoveredScanner? {
        await withCheckedContinuation { continuation in
            let finished = state.withLock { state -> DiscoveredScanner?? in
                guard state.isFinished else {
                    state.waiter = continuation
                    return nil
                }
                return .some(state.result)
            }
            if let finished { continuation.resume(returning: finished) }
        }
    }
}
