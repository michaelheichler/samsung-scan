import Foundation

public enum ScanEvent: Equatable, Sendable {
    case progress(page: Int, fraction: Double)
    case page(URL)
}
