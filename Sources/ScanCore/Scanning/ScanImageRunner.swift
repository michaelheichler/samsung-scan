import Foundation

public actor ScanImageRunner {
    static let openAttempts = 3
    static let busyRetryDelay: Duration = .seconds(2)
    static let pagePollInterval: Duration = .milliseconds(300)
    static let progressFlag = "--progress"

    public nonisolated let executable: URL?
    public nonisolated let configDirectory: SaneConfigDirectory?
    private var lastScan: Task<Void, Never>?
    private var systemConfigDirectories: [String]?
    private var environment: [String: String] = [:]

    public init(executable: URL? = ScanImageLocator.locate(), configDirectory: SaneConfigDirectory? = nil) {
        self.executable = executable
        self.configDirectory = configDirectory
    }

    public nonisolated var isInstalled: Bool { executable != nil }

    public func listDevices(discovered: [DiscoveredScanner] = []) async throws -> [ScannerDevice] {
        await prepareConfig(for: discovered)
        let result = try await run(["-L"])
        return DeviceList.parse(result.output)
    }

    // So that a failure keeps the system configuration instead of hiding its lines.
    private func prepareConfig(for discovered: [DiscoveredScanner]) async {
        environment = [:]
        guard let configDirectory, let directories = await defaultConfigDirectories() else { return }
        var system = ""
        if let file = SaneConfigSearch.firstFile(named: XeroxConfig.fileName, in: directories) {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { return }
            system = text
        }
        guard (try? configDirectory.writeXeroxConfig(XeroxConfig.merged(system: system, discovered: discovered)))
            != nil else { return }
        environment = configDirectory.environment
    }

    private func defaultConfigDirectories() async -> [String]? {
        if let systemConfigDirectories { return systemConfigDirectories }
        let debug = [SaneConfigSearch.debugVariable: SaneConfigSearch.debugLevel]
        guard let executable,
              let result = try? await ScanImageProcess(executable: executable, arguments: ["-V"], environment: debug).run()
        else { return nil }
        systemConfigDirectories = SaneConfigSearch.directories(inDebugOutput: result.errors)
        return systemConfigDirectories
    }

    // Because options such as highlight turn active only in some modes.
    public func capabilities(device: String, source: String, mode: String? = nil) async throws -> ScannerCapabilities {
        let modeArguments = mode.map { ["--mode=\($0)"] } ?? []
        let result = try await run(["--device-name=\(device)", "--source=\(source)"] + modeArguments + ["-A"])
        return ScannerCapabilities(options: ScannerOptionParser.parse(result.output))
    }

    public func scan(arguments: [String], batchFolder: URL) -> AsyncThrowingStream<URL, Error> {
        let events = scanEvents(arguments: arguments, batchFolder: batchFolder)
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: URL.self)
        let task = Task {
            do {
                for try await case .page(let page) in events {
                    continuation.yield(page)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        Self.cancel(task, whenTerminated: continuation)
        return stream
    }

    public func scanEvents(arguments: [String], batchFolder: URL) -> AsyncThrowingStream<ScanEvent, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: ScanEvent.self)
        let previous = lastScan
        let task = Task {
            // So that a new scan never opens the scanner while a cancelled one exits.
            await previous?.value
            await produce(arguments: arguments + [Self.progressFlag], batchFolder: batchFolder, into: continuation)
        }
        lastScan = task
        Self.cancel(task, whenTerminated: continuation)
        return stream
    }

    private static func cancel<Element>(
        _ task: Task<Void, Never>,
        whenTerminated continuation: AsyncThrowingStream<Element, Error>.Continuation
    ) {
        continuation.onTermination = { reason in
            if case .cancelled = reason {
                continuation.finish(throwing: CancellationError())
            }
            task.cancel()
        }
    }

    public func waitUntilIdle() async {
        await lastScan?.value
    }

    private func produce(
        arguments: [String],
        batchFolder: URL,
        into continuation: AsyncThrowingStream<ScanEvent, Error>.Continuation
    ) async {
        do {
            try FileManager.default.createDirectory(at: batchFolder, withIntermediateDirectories: true)
            var watcher = BatchFolderWatcher(folder: batchFolder)
            // Because a restart overwrites page001 and the watcher skips it.
            try await retryingWhileBusy(canRetry: { watcher.delivered.isEmpty }) {
                let result = try await runWatching(arguments, watcher: &watcher, continuation: continuation)
                if let failure = Self.failure(in: result, pagesDelivered: watcher.delivered.count) {
                    throw failure
                }
            }
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }

    private func runWatching(
        _ arguments: [String],
        watcher: inout BatchFolderWatcher,
        continuation: AsyncThrowingStream<ScanEvent, Error>.Continuation
    ) async throws -> ProcessResult {
        let process = try makeProcess(arguments)
        async let running = process.run()
        var reported: ScanEvent?
        while !process.hasEnded {
            if let event = Self.progressEvent(of: process), event != reported {
                reported = event
                continuation.yield(event)
            }
            for page in watcher.finishedPages(processEnded: false) {
                continuation.yield(.page(page))
            }
            try await Task.sleep(for: Self.pagePollInterval)
        }
        let result = try await running
        try Task.checkCancellation()
        for page in watcher.finishedPages(processEnded: true) {
            continuation.yield(.page(page))
        }
        return result
    }

    private func run(_ arguments: [String]) async throws -> ProcessResult {
        try await retryingWhileBusy {
            let result = try await makeProcess(arguments).run()
            if result.status != 0 {
                throw ScanImageError.fromScanImageErrors(result.errors)
            }
            return result
        }
    }

    private func retryingWhileBusy<Value>(
        canRetry: () -> Bool = { true },
        _ body: () async throws -> Value
    ) async throws -> Value {
        var attempt = 1
        while true {
            do {
                return try await body()
            } catch ScanImageError.scannerBusy where canRetry() {
                guard attempt < Self.openAttempts else { throw ScanImageError.scannerBusy(attempts: attempt) }
                attempt += 1
                try await Task.sleep(for: Self.busyRetryDelay)
            }
        }
    }

    private func makeProcess(_ arguments: [String]) throws -> ScanImageProcess {
        guard let executable else { throw ScanImageError.scanImageMissing }
        return ScanImageProcess(executable: executable, arguments: arguments, environment: environment)
    }

    private static func progressEvent(of process: ScanImageProcess) -> ScanEvent? {
        let reader = process.progress
        return reader.fraction.map { .progress(page: reader.page, fraction: $0) }
    }

    // Because the feeder reports "out of documents" after its last page.
    private static func failure(in result: ProcessResult, pagesDelivered: Int) -> ScanImageError? {
        let error = ScanImageError.fromScanImageErrors(ScanProgressReader.removingProgress(from: result.errors))
        if pagesDelivered == 0 { return error }
        if result.status == 0 || error == .feederEmpty { return nil }
        return error
    }
}
