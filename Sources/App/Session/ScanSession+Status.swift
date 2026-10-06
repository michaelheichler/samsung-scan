extension ScanSession {
    var statusText: String {
        if let title = phase.progressTitle { return title }
        if case .failed(let message) = phase { return message }
        if let outcome { return Self.text(for: outcome) }
        if devices.isEmpty { return "No scanner found." }
        if draft == nil { return "Select a scanner." }
        return pages.isEmpty ? "Ready to scan." : "\(Self.pageCount(pages.count)) ready to export."
    }

    var statusIsProblem: Bool {
        if case .failed = phase { return true }
        if case .exportFailed = outcome { return true }
        return false
    }

    // So that a file or launch error does not read as a scanner fault.
    static func failureMessage(for error: Error) -> String {
        if let scannerError = error as? ScanImageError { return scannerError.message }
        return "The action could not finish. \(error.localizedDescription)"
    }

    private static func text(for outcome: ScanOutcome) -> String {
        switch outcome {
        case .scanned(let count): "Scanned \(pageCount(count))."
        case .previewed: "Preview ready."
        case .cancelled: "Scan cancelled."
        case .exported(let fileName): "Saved \(fileName)."
        case .exportedFiles(let count): "Saved \(count) files."
        case .exportFailed(let message): message
        }
    }

    private static func pageCount(_ count: Int) -> String {
        count == 1 ? "1 page" : "\(count) pages"
    }
}
