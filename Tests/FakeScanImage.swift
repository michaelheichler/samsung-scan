import Foundation

enum TemporaryFolder {
    static func make() -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appending(path: "samsungscan-checks/\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

enum FakeScanImage {
    static func write(_ script: String, in folder: URL) -> URL {
        let executable = folder.appending(path: "scanimage")
        try! script.write(to: executable, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path(percentEncoded: false))
        return executable
    }
}

struct ScanOutcome: Sendable {
    let pages: [URL]
    let notes: [Bool]
    let error: (any Error)?

    var pageNames: [String] { pages.map(\.lastPathComponent) }

    static func collect(_ stream: AsyncThrowingStream<URL, Error>, noting note: () -> Bool = { false }) async -> ScanOutcome {
        var pages: [URL] = []
        var notes: [Bool] = []
        do {
            for try await page in stream {
                pages.append(page)
                notes.append(note())
            }
            return ScanOutcome(pages: pages, notes: notes, error: nil)
        } catch {
            return ScanOutcome(pages: pages, notes: notes, error: error)
        }
    }
}

struct EventOutcome: Sendable {
    let events: [ScanEvent]
    let error: (any Error)?

    static func collect(
        _ stream: AsyncThrowingStream<ScanEvent, Error>,
        seeing see: (ScanEvent) -> Void = { _ in }
    ) async -> EventOutcome {
        var events: [ScanEvent] = []
        do {
            for try await event in stream {
                events.append(event)
                see(event)
            }
            return EventOutcome(events: events, error: nil)
        } catch {
            return EventOutcome(events: events, error: error)
        }
    }
}

// So that fakes wait for markers the checks write, never for a fixed time.
struct FakeScan {
    static let markerWait = "awaitMarker() { n=0; while [ ! -e \"$state/$1\" ] && [ $n -lt 100 ]; do sleep 0.05; n=$((n + 1)); done; }\n"

    let folder = TemporaryFolder.make()

    var pages: URL { folder.appending(path: "pages") }

    func runner(_ body: String, configDirectory: SaneConfigDirectory? = nil) -> ScanImageRunner {
        let script = "#!/bin/sh\npages='\(path(pages))'\nstate='\(path(folder))'\n" + Self.markerWait + body
        return ScanImageRunner(executable: FakeScanImage.write(script, in: folder), configDirectory: configDirectory)
    }

    func scan(on runner: ScanImageRunner) async -> AsyncThrowingStream<URL, Error> {
        await runner.scan(arguments: [], batchFolder: pages)
    }

    func start(_ body: String) async -> (ScanImageRunner, AsyncThrowingStream<URL, Error>) {
        let runner = runner(body)
        return (runner, await scan(on: runner))
    }

    func run(_ body: String) async -> ScanOutcome {
        await ScanOutcome.collect(start(body).1)
    }

    func events(_ body: String, seeing see: (ScanEvent) -> Void = { _ in }) async -> EventOutcome {
        await EventOutcome.collect(runner(body).scanEvents(arguments: [], batchFolder: pages), seeing: see)
    }

    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: path(folder.appending(path: name)))
    }

    func touch(_ name: String) {
        FileManager.default.createFile(atPath: path(folder.appending(path: name)), contents: nil)
    }

    func awaitMarker(_ name: String, timeout: Duration = .seconds(5)) async {
        let deadline = ContinuousClock.now + timeout
        while !exists(name), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func lines(of name: String) -> [String] {
        let text = (try? String(contentsOf: folder.appending(path: name), encoding: .utf8)) ?? ""
        return text.split(separator: "\n").map(String.init)
    }

    private func path(_ url: URL) -> String {
        url.path(percentEncoded: false)
    }
}
