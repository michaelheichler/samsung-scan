import SwiftUI

struct ExportSheet: View {
    private static let width = 360.0
    private static let spacing = 16.0

    let session: ScanSession
    @Environment(\.dismiss) private var dismiss
    @AppStorage("exportFormat") private var format = ExportFormat.pdf
    @AppStorage("exportScope") private var scope = ExportScope.all
    @AppStorage("exportJPEGQuality") private var jpegQuality = PageExporter.defaultJPEGQuality
    @AppStorage("exportSearchableText") private var makesTextSearchable = true
    @AppStorage("exportGrouping") private var grouping = ExportGrouping.filePerDocument
    @ViewState private var documents: ExportPlan
    @ViewState private var stagedFile: ExportedFile?
    @ViewState private var isSavingFile = false
    @ViewState private var isChoosingFolder = false
    @ViewState private var isWriting = false
    @ViewState private var isWaitingForText = false
    @ViewState private var writeTask: Task<Void, Never>?
    @ViewState private var errorMessage: String?

    // So that the documents and their names stay fixed while the sheet is open.
    init(session: ScanSession) {
        self.session = session
        _documents = ViewState(initialValue: session.confirmedExportPlan())
    }

    // So that a page corrected after the sheet opened exports with its own text.
    private var job: ExportJob {
        let selected = session.selectedPageIDs
        let current = documents.current(in: session.pages)
        var plan = scope == .selected && !selected.isEmpty ? current.keeping(selected) : current
        if format == .pdf && grouping == .oneFile {
            plan = plan.joined()
        }
        return ExportJob(
            plan: plan, exporter: PageExporter(format: format, jpegQuality: jpegQuality),
            makesTextSearchable: makesTextSearchable)
    }

    private var summary: LocalizedStringKey {
        let count = job.pages.count
        let documentCount = job.plan.documents.count
        if format == .pdf && documentCount > 1 {
            return "Saves \(documentCount) documents with ^[\(count) page](inflect: true) as separate PDF files."
        }
        return job.writesSeveralFiles
            ? "Saves ^[\(count) page](inflect: true) as separate \(format.name) files."
            : "Saves ^[\(count) page](inflect: true) as one \(format.name) file."
    }

    private var folderMessage: String {
        job.plan.documents.count > 1
            ? "Choose a folder for the exported documents."
            : "Choose a folder for the exported pages."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            Text("Export")
                .font(.headline)
            ExportOptionsForm(
                format: $format, scope: $scope, jpegQuality: $jpegQuality, makesTextSearchable: $makesTextSearchable,
                grouping: $grouping, pageCount: session.pages.count, selectedCount: session.selectedPages.count,
                documentCount: documents.documents.count)
            Text(summary)
                .foregroundStyle(.secondary)
            if session.openSuggestionCount > 0 {
                OpenSplitsNote(count: session.openSuggestionCount, acceptAll: acceptAllSplits)
                    .disabled(isWriting)
            }
            if isWaitingForText {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Reading the text of the pages…")
                        .foregroundStyle(.secondary)
                }
            }
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel, action: close)
                    .keyboardShortcut(.cancelAction)
                Button("Export…", action: export)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isWriting || job.pages.isEmpty)
            }
            .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder], onCompletion: chooseFolder)
            .fileDialogMessage(folderMessage)
            .fileDialogConfirmationLabel("Export")
        }
        .padding(Self.spacing)
        .frame(width: Self.width)
        .fileExporter(
            isPresented: $isSavingFile,
            document: stagedFile,
            contentType: format.contentType,
            defaultFilename: stagedFile?.fileName,
            onCompletion: saveFile)
        .onDisappear(perform: cancelWrite)
    }

    private func export() {
        errorMessage = nil
        if job.writesSeveralFiles {
            isChoosingFolder = true
        } else {
            stage(job)
        }
    }

    private func stage(_ job: ExportJob) {
        perform {
            let file = try await withPageText(job).stage(in: session.workFolder)
            try Task.checkCancellation()
            stagedFile = file
            isSavingFile = true
        }
    }

    private func chooseFolder(_ result: Result<URL, Error>) {
        switch result {
        case .success(let folder):
            write(job, into: folder)
        case .failure(let error):
            fail(error)
        }
    }

    // So that a cancel after the write returns removes the files it never reported.
    private func write(_ job: ExportJob, into folder: URL) {
        perform {
            let files = try await withPageText(job).write(into: folder)
            guard !Task.isCancelled else {
                PageExporter.remove(files)
                throw CancellationError()
            }
            finish(files)
        }
    }

    private func acceptAllSplits() {
        session.acceptAllSuggestedSplits()
        documents = session.confirmedExportPlan()
    }

    // So that a PDF exported right after a scan still carries the text of every page.
    private func withPageText(_ job: ExportJob) async throws -> ExportJob {
        guard job.needsPageText else { return job }
        isWaitingForText = true
        defer { isWaitingForText = false }
        var job = job
        job.texts = try await session.textRecognition.finishedTexts(of: job.pages)
        return job
    }

    // So that a write the user cancelled never reveals files or reports a result.
    private func perform(_ work: @escaping @MainActor () async throws -> Void) {
        isWriting = true
        writeTask = Task {
            do {
                try await work()
            } catch {
                if !Task.isCancelled { fail(error) }
            }
            isWriting = false
        }
    }

    private func saveFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let file):
            finish([file])
        case .failure(let error):
            fail(error)
        }
    }

    private func finish(_ files: [URL]) {
        session.recordExport(.success(files))
        NSWorkspace.shared.activateFileViewerSelecting(files)
        dismiss()
    }

    private func fail(_ error: Error) {
        session.recordExport(.failure(error))
        errorMessage = error.localizedDescription
    }

    private func close() {
        dismiss()
    }

    // So that a sheet closed by any path stops reporting its write.
    private func cancelWrite() {
        writeTask?.cancel()
    }
}
