import Foundation
import Synchronization

enum CheckLog {
    static let failures = Mutex(0)

    static var passed: Bool { failures.withLock { $0 == 0 } }
}

func expect(_ condition: Bool, _ name: String) {
    if condition {
        print("ok    \(name)")
    } else {
        print("FAIL  \(name)")
        CheckLog.failures.withLock { $0 += 1 }
    }
}

func runConcurrently(_ checks: [@Sendable () async -> Void]) async {
    await withTaskGroup(of: Void.self) { group in
        for check in checks {
            group.addTask { await check() }
        }
    }
}

// So that a main actor check can pass a closure that touches main actor state.
func caughtError(
    isolation: isolated (any Actor)? = #isolation, _ body: () async throws -> Void
) async -> (any Error)? {
    do {
        try await body()
        return nil
    } catch {
        return error
    }
}

func fixtureURL(_ name: String) -> URL {
    URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "Fixtures/\(name).txt")
}

func fixture(_ name: String) -> String {
    try! String(contentsOf: fixtureURL(name), encoding: .utf8)
}
