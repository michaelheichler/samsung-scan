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
    @ViewState private var name = ExportFileName(date: .now)
    @ViewState private var stagedFile: ExportedFile?
    @ViewState private var isSavingFile = false
    @ViewState private var isChoosingFolder = false
    @ViewState private var isWriting = false
    @ViewState private var isWaitingForText = false
    @ViewState private var writeTask: Task<Void, Never>?
    @ViewState private var errorMessage: String?

    private var job: ExportJob {
        let selected = session.selectedPages
        let pages = scope == .selected && !selected.isEmpty ? selected : session.pages
        return ExportJob(
            pages: pages, exporter: PageExporter(format: format, jpegQuality: jpegQuality), name: name,
            makesTextSearchable: makesTextSearchable)
    }

    private var summary: LocalizedStringKey {
        let count = job.pages.count
        return job.writesSeveralFiles
            ? "Saves ^[\(count) page](inflect: true) as separate \(format.name) files."
            : "Saves ^[\(count) page](inflect: true) as one \(format.name) file."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            Text("Export")
                .font(.headline)
            ExportOptionsForm(
                format: $format, scope: $scope, jpegQuality: $jpegQuality, makesTextSearchable: $makesTextSearchable,
                pageCount: session.pages.count, selectedCount: session.selectedPages.count)
            Text(summary)
                .foregroundStyle(.secondary)
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
            .fileDialogMessage("Choose a folder for the exported pages.")
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

    private func write(_ job: ExportJob, into folder: URL) {
        perform {
            let files = try await withPageText(job).write(into: folder)
            try Task.checkCancellation()
            finish(files)
        }
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
