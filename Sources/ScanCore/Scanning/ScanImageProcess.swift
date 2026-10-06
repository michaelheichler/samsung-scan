import Foundation
import Synchronization

final class ScanImageProcess: Sendable {
    // Because SIGKILL skips the release and leaves the scan unit locked.
    static let terminationGrace: Duration = .seconds(15)

    private struct Captured {
        var data = Data()
        var isOpen = true
    }

    private struct State {
        var output = Captured()
        var errors = Captured()
        var progress = ScanProgressReader()
        var pid: pid_t?
        var status: Int32?
        var hasEnded = false
        var stopRequested = false
        var waiter: CheckedContinuation<ProcessResult, Error>?
    }

    private let process = Process()
    private let state = Mutex(State())

    init(executable: URL, arguments: [String], environment: [String: String] = [:]) {
        process.executableURL = executable
        process.arguments = arguments
        if !environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        }
    }

    var hasEnded: Bool {
        state.withLock { $0.hasEnded }
    }

    var progress: ScanProgressReader {
        state.withLock { $0.progress }
    }

    func run() async throws -> ProcessResult {
        try Task.checkCancellation()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                launch(resumingWith: continuation)
            }
        } onCancel: {
            stop()
        }
    }

    private func launch(resumingWith continuation: CheckedContinuation<ProcessResult, Error>) {
        state.withLock { $0.waiter = continuation }
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        collect(output.fileHandleForReading, into: \.output)
        collect(errors.fileHandleForReading, into: \.errors)
        process.terminationHandler = { [self] finished in
            update {
                $0.pid = nil
                $0.status = finished.terminationStatus
            }
        }
        do {
            try process.run()
        } catch {
            output.fileHandleForReading.readabilityHandler = nil
            errors.fileHandleForReading.readabilityHandler = nil
            let waiter = state.withLock { state in
                state.hasEnded = true
                defer { state.waiter = nil }
                return state.waiter
            }
            waiter?.resume(throwing: error)
            return
        }
        let pid = process.processIdentifier
        let stopRequested = state.withLock { state in
            if state.status == nil { state.pid = pid }
            return state.stopRequested
        }
        if stopRequested { stop() }
    }

    private func collect(_ handle: FileHandle, into stream: WritableKeyPath<State, Captured> & Sendable) {
        handle.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
            }
            update { state in
                if chunk.isEmpty {
                    state[keyPath: stream].isOpen = false
                } else {
                    state[keyPath: stream].data.append(chunk)
                    if stream == \State.errors { state.progress.consume(chunk) }
                }
            }
        }
    }

    private func update(_ change: (inout State) -> Void) {
        let finished = state.withLock { state -> (CheckedContinuation<ProcessResult, Error>, ProcessResult)? in
            change(&state)
            guard !state.output.isOpen, !state.errors.isOpen,
                  let status = state.status, let waiter = state.waiter
            else { return nil }
            state.waiter = nil
            state.hasEnded = true
            let result = ProcessResult(
                status: status,
                output: String(decoding: state.output.data, as: UTF8.self),
                errors: String(decoding: state.errors.data, as: UTF8.self)
            )
            return (waiter, result)
        }
        if let (waiter, result) = finished {
            waiter.resume(returning: result)
        }
    }

    private func stop() {
        let pid = state.withLock { state in
            state.stopRequested = true
            return state.pid
        }
        guard let pid else { return }
        kill(pid, SIGTERM)
        Task { [self] in
            try? await Task.sleep(for: Self.terminationGrace)
            if let pid = state.withLock({ $0.pid }) {
                kill(pid, SIGKILL)
            }
        }
    }
}
