import Foundation

public enum FileNameStem {
    public static let maximumLength = 100

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
        guard stem.count > maximumLength else { return stem }
        let head = stem.prefix(maximumLength + 1)
        let cut = head.lastIndex(of: " ").map { head[..<$0] } ?? head.prefix(maximumLength)
        return String(cut).trimmingCharacters(in: .whitespaces)
    }
}
