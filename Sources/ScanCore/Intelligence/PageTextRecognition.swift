import Foundation
import Observation

@MainActor
@Observable
public final class PageTextRecognition {
    public typealias Recognize = @concurrent @Sendable (URL) async throws -> PageText
    public typealias WarmUp = @concurrent @Sendable () async -> Void

    public private(set) var texts: [ScannedPage.ID: PageText] = [:]
    public private(set) var states: [ScannedPage.ID: PageTextState] = [:]
    @ObservationIgnored private var sourceFiles: [ScannedPage.ID: URL] = [:]
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
            self.finish(page, with: text)
        }
        tasks[page.id] = task
        lastTask = task
    }

    // So that text from a corrected file never joins the old image.
    public func text(of page: ScannedPage) -> PageText? {
        sourceFiles[page.id] == page.file ? texts[page.id] : nil
    }

    public func cancel(_ id: ScannedPage.ID) {
        tasks.removeValue(forKey: id)?.cancel()
        texts[id] = nil
        sourceFiles[id] = nil
        states[id] = nil
    }

    public func cancelAll() {
        for id in states.keys {
            cancel(id)
        }
    }

    private func finish(_ page: ScannedPage, with text: PageText?) {
        tasks[page.id] = nil
        texts[page.id] = text
        sourceFiles[page.id] = page.file
        states[page.id] = text == nil ? .failed : .done
    }
}
