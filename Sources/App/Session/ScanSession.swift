import Foundation
import Observation

@MainActor
@Observable
final class ScanSession {
    private(set) var phase: ScanPhase = .idle
    var outcome: ScanOutcome?
    private(set) var devices: [ScannerDevice] = []
    private(set) var listedNetworkScanners: [DiscoveredScanner] = []
    var selectedDeviceName: String? {
        didSet {
            if selectedDeviceName != oldValue { deviceDidChange() }
        }
    }
    private(set) var capabilitiesBySource: [String: ScannerCapabilities] = [:]
    var draft: ScanRequest? {
        didSet {
            if draft != oldValue { draftDidChange(from: oldValue) }
        }
    }
    private(set) var previewImage: URL?
    private(set) var selectedRegion: ScanRegion?
    private(set) var lastPickedPaperID: String?
    private(set) var pages: [ScannedPage] = []
    var pageSelection = PageSelection()

    let paperCatalog: PaperCatalog?
    let workFolder: WorkFolder
    @ObservationIgnored private let runner: ScanImageRunner
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var workID = UUID()
    @ObservationIgnored private let stallTimeout: Duration
    @ObservationIgnored private var stallWatch: Task<Void, Never>?
    @ObservationIgnored let networkWatch = NetworkScannerWatch()
    @ObservationIgnored let textRecognition = PageTextRecognition()
    @ObservationIgnored let factsTracker = DocumentFactsTracker()
    @ObservationIgnored let blankCheck = BlankPageCheck()
    @ObservationIgnored let corrections: PageCorrections

    init(
        runner: ScanImageRunner = ScanImageRunner(configDirectory: .forApp),
        paperCatalog: PaperCatalog? = try? PaperCatalog.bundled(),
        workFolder: WorkFolder = WorkFolder(),
        stallTimeout: Duration = .seconds(60)
    ) {
        self.runner = runner
        self.paperCatalog = paperCatalog
        self.workFolder = workFolder
        self.stallTimeout = stallTimeout
        corrections = PageCorrections(folder: workFolder.correctionsFolder)
        watchDocumentFacts()
    }

    var currentCapabilities: ScannerCapabilities? {
        draft.flatMap { capabilitiesBySource[$0.source] }
    }

    var availablePapers: [PaperSize] {
        currentCapabilities.map(availablePapers(for:)) ?? []
    }

    var canScan: Bool {
        draft != nil && !phase.isBusy
    }

    func discoverScanners() {
        guard runner.isInstalled else {
            phase = .failed(message: ScanImageError.scanImageMissing.message)
            return
        }
        networkWatch.refreshPending = false
        let network = networkWatch.scanners
        perform(.discovering) { [runner] in
            let found = try await runner.listDevices(discovered: network)
            self.devices = found
            self.listedNetworkScanners = network
            if !found.contains(where: { $0.name == self.selectedDeviceName }) {
                self.selectedDeviceName = found.first?.name
            }
        }
    }

    func preview() {
        guard canPreview, let draft, let capabilities = currentCapabilities else { return }
        let request = draft.preview(for: capabilities)
        perform(.previewing) {
            for try await file in await self.pageStream(for: request) {
                self.previewImage = file
            }
            self.outcome = .previewed
        }
    }

    func scan() {
        guard canScan, let request = draft else { return }
        perform(.scanning(ScanProgress())) {
            var progress = ScanProgress()
            self.watchForStall()
            defer { self.stallWatch?.cancel() }
            for try await event in await self.eventStream(for: request) {
                switch event {
                case .page(let file):
                    let page = ScannedPage(file: file, resolution: request.resolution, region: request.region)
                    self.pages.append(page)
                    self.textRecognition.start(page)
                    self.blankCheck.start(page)
                    progress.pageDelivered()
                case .progress(let page, let fraction):
                    progress.record(page: page, fraction: fraction, at: .now)
                }
                self.watchForStall()
                if !Task.isCancelled { self.phase = .scanning(progress) }
            }
            self.outcome = .scanned(pageCount: progress.pagesSoFar)
        }
    }

    // So that a silent scanner shows a message instead of spinning forever.
    private func watchForStall() {
        stallWatch?.cancel()
        stallWatch = Task { [weak self, stallTimeout] in
            try? await Task.sleep(for: stallTimeout)
            guard !Task.isCancelled, let self, case .scanning(var progress) = self.phase else { return }
            progress.isStalled = true
            self.phase = .scanning(progress)
        }
    }

    func cancel() {
        guard phase.isCancellable else { return }
        phase = .stopping
        task?.cancel()
    }

    // So that quitting never leaves scanimage holding the scanner (ISS-003).
    func shutDown() async {
        cancel()
        await task?.value
        await runner.waitUntilIdle()
    }

    func selectPaper(_ paper: PaperSize) {
        lastPickedPaperID = paper.id
        selectedRegion = nil
        draft?.region = ScanRegion(paper: paper)
    }

    func selectRegion(_ region: ScanRegion) {
        draft?.region = region
        selectedRegion = draft?.region
    }

    func remove(_ page: ScannedPage) {
        pages.removeAll { $0.id == page.id }
        textRecognition.cancel(page.id)
        blankCheck.cancel(page.id)
        corrections.forget(page.id)
    }

    // So that text, blank check, and facts follow the new file, they start again.
    func replace(_ page: ScannedPage, with corrected: ScannedPage) {
        guard let index = pages.firstIndex(of: page) else { return }
        pages[index] = corrected
        textRecognition.cancel(page.id)
        blankCheck.cancel(page.id)
        textRecognition.start(corrected)
        blankCheck.start(corrected)
    }

    func move(_ page: ScannedPage, by offset: Int) {
        guard let index = pages.firstIndex(of: page), pages.indices.contains(index + offset) else { return }
        pages.swapAt(index, index + offset)
    }

    func discardAllPages() {
        pages.removeAll()
        textRecognition.cancelAll()
        blankCheck.cancelAll()
        corrections.forgetAll()
        outcome = nil
    }

    func recordExport(_ result: Result<[URL], Error>) {
        outcome = switch result {
        case .success(let urls) where urls.count == 1: .exported(fileName: urls.first?.lastPathComponent ?? "")
        case .success(let urls): .exportedFiles(count: urls.count)
        case .failure(let error): .exportFailed(message: error.localizedDescription)
        }
    }

    private func pageStream(for request: ScanRequest) async -> AsyncThrowingStream<URL, Error> {
        let folder = workFolder.makeBatchFolderURL()
        return await runner.scan(arguments: request.arguments(batchFolder: folder), batchFolder: folder)
    }

    private func eventStream(for request: ScanRequest) async -> AsyncThrowingStream<ScanEvent, Error> {
        let folder = workFolder.makeBatchFolderURL()
        return await runner.scanEvents(arguments: request.arguments(batchFolder: folder), batchFolder: folder)
    }

    private func perform(_ busyPhase: ScanPhase, _ work: @escaping @MainActor () async throws -> Void) {
        task?.cancel()
        let id = UUID()
        workID = id
        phase = busyPhase
        outcome = nil
        task = Task {
            do {
                try await work()
                try Task.checkCancellation()
                finish(id, with: .idle)
            } catch {
                await handle(error, of: id)
            }
        }
    }

    private func handle(_ error: Error, of id: UUID) async {
        guard id == workID else { return }
        if phase == .stopping {
            await runner.waitUntilIdle()
            outcome = .cancelled
            finish(id, with: .idle)
        } else if error is CancellationError {
            finish(id, with: .idle)
        } else {
            finish(id, with: .failed(message: Self.failureMessage(for: error)))
        }
    }

    private func finish(_ id: UUID, with next: ScanPhase) {
        guard id == workID else { return }
        phase = next
        if next == .idle && networkWatch.refreshPending { discoverScanners() }
    }

    private func deviceDidChange() {
        capabilitiesBySource = [:]
        previewImage = nil
        selectedRegion = nil
        // So that a failed capability load never leaves a draft for the old device.
        draft = nil
        guard selectedDeviceName != nil else { return }
        loadCapabilities(source: DraftDefaults.deviceDefaultSource)
    }

    private func loadCapabilities(source: String, mode: String? = nil) {
        guard let device = selectedDeviceName else { return }
        perform(.loadingCapabilities) { [runner] in
            var capabilities = try await runner.capabilities(device: device, source: source, mode: mode)
            // So that a new source lists the options active in the mode the draft keeps.
            if mode == nil, let kept = self.draft?.mode, capabilities.modes.contains(kept),
               !capabilities.describes(mode: kept) {
                capabilities = try await runner.capabilities(device: device, source: source, mode: kept)
            }
            self.adopt(capabilities, device: device, requestedSource: source)
        }
    }

    private func adopt(_ capabilities: ScannerCapabilities, device: String, requestedSource: String) {
        let source = requestedSource.isEmpty ? capabilities.defaultSource ?? requestedSource : requestedSource
        capabilitiesBySource[source] = capabilities
        guard let current = draft else {
            draft = DraftDefaults.request(
                device: device, source: source, capabilities: capabilities, papers: availablePapers(for: capabilities))
            return
        }
        draft = current.validated(against: capabilities)
    }

    private func availablePapers(for capabilities: ScannerCapabilities) -> [PaperSize] {
        guard let area = capabilities.scanArea else { return paperCatalog?.sizes ?? [] }
        return paperCatalog?.sizes(fitting: area) ?? [.fullArea(area)]
    }

    // Because validation is idempotent, the nested didSet ends after one pass.
    private func draftDidChange(from old: ScanRequest?) {
        guard var next = draft else { return }
        if let old, old.source != next.source {
            next.pageLimit = DraftDefaults.pageLimit(for: next.source)
        }
        let capabilities = capabilitiesBySource[next.source]
        if let capabilities {
            next = next.validated(against: capabilities)
        }
        if next != draft {
            draft = next
        } else if let capabilities {
            if !capabilities.describes(mode: next.mode) {
                loadCapabilities(source: next.source, mode: next.mode)
            }
        } else {
            loadCapabilities(source: next.source)
        }
    }
}
