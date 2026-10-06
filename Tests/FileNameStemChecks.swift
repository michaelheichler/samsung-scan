import Foundation

enum FileNameStemChecks {
    static func run() {
        longCJKStemFitsTheByteLimitAndKeepsItsStart()
        cjkWordsAreCutAtASpaceWithinTheByteLimit()
        stemEndsOnAWholeCharacter("e\u{301}", "an e with a combining accent")
        stemEndsOnAWholeCharacter("🇩🇪", "a flag made of two scalars")
    }

    static func longCJKStemFitsTheByteLimitAndKeepsItsStart() {
        let stem = String(repeating: "漢", count: 100)
        let capped = FileNameStem.joining([stem])
        expect(
            !capped.isEmpty && stem.hasPrefix(capped) && capped.utf8.count <= FileNameStem.maximumBytes,
            "a stem of 100 three byte characters is cut to the byte limit and keeps its start")
    }

    static func cjkWordsAreCutAtASpaceWithinTheByteLimit() {
        let words = Array(repeating: "請求書請求書請求書請", count: 10)
        let stem = words.joined(separator: " ")
        let capped = FileNameStem.joining([stem])
        let nextWord = words[0]
        expect(
            !capped.isEmpty && stem.hasPrefix(capped + " ")
                && capped.utf8.count <= FileNameStem.maximumBytes
                && (capped + " " + nextWord).utf8.count > FileNameStem.maximumBytes,
            "a stem of three byte words keeps the whole words that fit the byte limit and ends at a space")
    }

    static func stemEndsOnAWholeCharacter(_ character: Character, _ described: String) {
        let stem = "a" + String(repeating: character, count: 100)
        let capped = FileNameStem.joining([stem])
        expect(
            capped.last == character && stem.hasPrefix(capped) && capped.utf8.count <= FileNameStem.maximumBytes,
            "a stem of \(described) is cut within the byte limit and ends on a whole character")
    }
}
