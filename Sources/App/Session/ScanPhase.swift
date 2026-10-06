import Foundation

enum ScanPhase: Equatable, Sendable {
    // So that a short estimate does not flicker with every poll.
    private static let secondsStep = 10
    private static let remainingStyle = Duration.UnitsFormatStyle(
        allowedUnits: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 1)
    private static let percentStyle = FloatingPointFormatStyle<Double>.Percent.percent.precision(.fractionLength(0))

    case idle
    case discovering
    case loadingCapabilities
    case previewing
    case scanning(ScanProgress)
    case stopping
    case failed(message: String)

    var isBusy: Bool {
        switch self {
        case .idle, .failed: false
        case .discovering, .loadingCapabilities, .previewing, .scanning, .stopping: true
        }
    }

    var isCancellable: Bool {
        switch self {
        case .previewing, .scanning: true
        default: false
        }
    }

    var holdsScanner: Bool {
        isCancellable || self == .stopping
    }

    var progressTitle: String? {
        switch self {
        case .idle, .failed: nil
        case .discovering: "Looking for scanners…"
        case .loadingCapabilities: "Reading scanner settings…"
        case .previewing: "Scanning preview…"
        case .scanning(let progress) where progress.isStalled: "The scanner stopped responding"
        case .scanning(let progress): Self.title(for: progress)
        case .stopping: "Stopping the scanner…"
        }
    }

    var progressFraction: Double? {
        guard case .scanning(let progress) = self else { return nil }
        return progress.fraction
    }

    var progressDetail: String? {
        guard case .scanning(let progress) = self, !progress.isStalled, let remaining = progress.remaining
        else { return nil }
        return "About \(Self.rounded(remaining).formatted(Self.remainingStyle)) left"
    }

    var isStalled: Bool {
        guard case .scanning(let progress) = self else { return false }
        return progress.isStalled
    }

    private static func title(for progress: ScanProgress) -> String {
        guard let fraction = progress.fraction else { return "Scanning page \(progress.page)…" }
        return "Scanning page \(progress.page), \(fraction.formatted(percentStyle))"
    }

    private static func rounded(_ remaining: Duration) -> Duration {
        let seconds = Int(remaining.components.seconds)
        guard seconds < 60 else { return remaining }
        return .seconds(max(1, (seconds + secondsStep - 1) / secondsStep) * secondsStep)
    }
}
