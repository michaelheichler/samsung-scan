import Foundation

public enum FileNameStem {
    public static let maximumLength = 100
    // Because APFS allows 255 bytes per name, this leaves room for a suffix.
    public static let maximumBytes = 240

    // Because Finder shows a colon as a slash and the file system rejects a slash.
    private static let rejected = CharacterSet(charactersIn: "/:").union(.controlCharacters)

    public static func joining(_ parts: [String]) -> String {
        let stem = parts.map(cleaned).filter { !$0.isEmpty }.joined(separator: " ")
        return capped(String(stem.drop { $0 == "." || $0.isWhitespace }))
    }

    static func cleaned(_ part: String) -> String {
        part.unicodeScalars
            .split { rejected.contains($0) || $0.properties.isWhitespace }
            .map { String(String.UnicodeScalarView($0)) }
            .joined(separator: " ")
    }

    static func capped(_ stem: String) -> String {
        let head = longestFittingPrefix(of: stem)
        guard head.endIndex < stem.endIndex else { return stem }
        let endsAtWord = stem[head.endIndex] == " "
        let cut = endsAtWord ? head : head.lastIndex(of: " ").map { head[..<$0] } ?? head
        return String(cut).trimmingCharacters(in: .whitespaces)
    }

    private static func longestFittingPrefix(of stem: String) -> Substring {
        var end = stem.startIndex
        var characters = 0
        var bytes = 0
        while end < stem.endIndex {
            let size = stem[end].utf8.count
            guard characters < maximumLength, bytes + size <= maximumBytes else { break }
            characters += 1
            bytes += size
            end = stem.index(after: end)
        }
        return stem[..<end]
    }
}
