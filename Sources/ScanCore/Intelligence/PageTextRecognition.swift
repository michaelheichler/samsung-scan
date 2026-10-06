import Foundation
import Observation

@MainActor
@Observable
public final class PageTextRecognition {
    public typealias Recognize = @concurrent @Sendable (URL) async throws -> PageText
    public typealias WarmUp = @concurrent @Sendable () async -> Void

    public private(set) var texts: [ScannedPage.ID: PageText] = [:]
    public private(set) var states: [ScannedPage.ID: PageTextState] = [:]
    @ObservationIgnored private var tasks: [ScannedPage.ID: Task<Void, Never>] = [:]
    // So that pages run one at a time and a feeder scan keeps the Mac responsive.
    @ObservationIgnored private var lastTask: Task<Void, Never>?
    @ObservationIgnored private let recognize: Recognize
    @ObservationIgnored private let warmUpWork: WarmUp

    public init(
        recognize: @escaping Recognize = TextRecognizer.recognize(fileAt:),
        warmUp: @escaping WarmUp = TextRecognizer.warmUp
    ) {
        self.recognize = recognize
        warmUpWork = warmUp
    }

    // So that the first page waits for the model load instead of loading it twice.
    public func warmUp() {
        let previous = lastTask
        lastTask = Task(priority: .utility) { [warmUpWork] in
            await previous?.value
            await warmUpWork()
        }
    }

    public func start(_ page: ScannedPage) {
        guard states[page.id] == nil else { return }
        states[page.id] = .recognizing
        let previous = lastTask
        let task = Task(priority: .utility) { [recognize] in
            await previous?.value
            guard !Task.isCancelled else { return }
            let text = try? await recognize(page.file)
            guard !Task.isCancelled else { return }
            self.finish(page.id, with: text)
        }
        tasks[page.id] = task
        lastTask = task
    }

    public func cancel(_ id: ScannedPage.ID) {
        tasks.removeValue(forKey: id)?.cancel()
        texts[id] = nil
        states[id] = nil
    }

    public func cancelAll() {
        for id in states.keys {
            cancel(id)
        }
    }

    private func finish(_ id: ScannedPage.ID, with text: PageText?) {
        tasks[id] = nil
        texts[id] = text
        states[id] = text == nil ? .failed : .done
    }
}
