import Foundation

public enum ScanImageError: LocalizedError, Equatable, Sendable {
    case scannerBusy(attempts: Int)
    case coverOpen
    case feederEmpty
    case paperJam
    case ioError
    case pageFailed(log: String)
    case scanImageMissing
    case unknown(log: String)

    public var errorDescription: String? { message }

    public var message: String {
        switch self {
        case .scannerBusy(let attempts) where attempts > 1:
            "The scanner is busy or cannot be reached. The app tried \(attempts) times. "
                + "Wait until other scans finish, check that the scanner is on, and try again."
        case .scannerBusy:
            "The scanner is busy or cannot be reached. "
                + "Wait until other scans finish, check that the scanner is on, and try again."
        case .coverOpen:
            "The scanner cover is open. Close it and try again."
        case .feederEmpty:
            "The document feeder is empty. Load paper and try again."
        case .paperJam:
            "Paper is jammed in the document feeder. Remove it and try again."
        case .ioError:
            "The connection to the scanner failed during the scan. "
                + "Check that the scanner is on and reachable, then try again."
        case .pageFailed:
            "The scanner stopped before the page was complete, so the page was not saved. Try again."
        case .scanImageMissing:
            "scanimage is not installed. Install it in Terminal with: brew install sane-backends"
        case .unknown(let log):
            Self.summary(of: log).map { "The scanner reported an error: \($0)" }
                ?? "The scanner returned no page and gave no reason."
        }
    }

    static func fromScanImageErrors(_ text: String) -> ScanImageError {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        func mentions(_ phrase: String) -> Bool {
            lines.contains { $0.contains(phrase) }
        }
        let openFailed = lines.contains { $0.contains("open of device") && $0.contains("failed") }
        if openFailed || mentions("Device busy") { return .scannerBusy(attempts: 1) }
        if mentions("Scanner cover is open") { return .coverOpen }
        if mentions("Document feeder jammed") { return .paperJam }
        if mentions("Document feeder out of documents") { return .feederEmpty }
        if mentions("Error during device I/O") { return .ioError }
        if mentions("Batch terminated") { return .pageFailed(log: text) }
        return .unknown(log: text)
    }

    private static let toolPrefixes = ["scanimage: ", "sane_start: ", "sane_read: "]

    private static func summary(of log: String) -> String? {
        let lines = log.split(whereSeparator: \.isNewline).map { line in
            toolPrefixes.reduce(String(line)) { $0.replacing($1, with: "") }
                .trimmingCharacters(in: .whitespaces)
        }
        let text = lines.filter { !$0.isEmpty }.joined(separator: " ")
        return text.isEmpty ? nil : text
    }
}
