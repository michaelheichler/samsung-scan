import Foundation

// Because scanimage ends progress lines with "\r" and page lines with "\n".
struct ScanProgressReader: Sendable {
    static let progressPrefix = "Progress: "
    static let pagePrefix = "Scanning page "

    private(set) var page = 1
    private(set) var fraction: Double?
    private var pending = Data()

    static func removingProgress(from text: String) -> String {
        text.replacing(/Progress: [^\r\n]*\r/, with: "")
    }

    static func fraction(in line: String) -> Double? {
        let text = line.trimmingCharacters(in: .whitespaces)
        guard text.hasPrefix(progressPrefix), text.hasSuffix("%"),
              let percent = Double(text.dropFirst(progressPrefix.count).dropLast().trimmingCharacters(in: .whitespaces))
        else { return nil }
        return min(max(percent / 100, 0), 1)
    }

    static func pageNumber(in line: String) -> Int? {
        let text = line.trimmingCharacters(in: .whitespaces)
        guard text.hasPrefix(pagePrefix) else { return nil }
        return Int(text.dropFirst(pagePrefix.count))
    }

    mutating func consume(_ chunk: Data) {
        pending.append(chunk)
        while let end = pending.firstIndex(where: { $0 == UInt8(ascii: "\r") || $0 == UInt8(ascii: "\n") }) {
            read(String(decoding: pending[pending.startIndex..<end], as: UTF8.self))
            pending.removeSubrange(pending.startIndex...end)
        }
    }

    private mutating func read(_ line: String) {
        if let number = Self.pageNumber(in: line) {
            page = number
            fraction = nil
        } else if let next = Self.fraction(in: line) {
            fraction = next
        }
    }
}
