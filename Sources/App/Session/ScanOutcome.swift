enum ScanOutcome: Equatable, Sendable {
    case scanned(pageCount: Int)
    case previewed
    case cancelled
    case exported(fileName: String)
    case exportedFiles(count: Int)
    case exportFailed(message: String)
}
