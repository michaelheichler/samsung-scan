import Foundation

enum ModelInputCutChecks {
    static func run() async {
        await textWithinBudgetComesBackUnchanged()
        await longProseIsCutToAPrefixWithinBudget()
        await digitHeavyTextIsCutToAPrefixWithinBudget()
        await emptyOrNegativeBudgetGivesEmptyText()
    }

    private static let budget = 6656
    private static let prose = String(
        repeating: "Sehr geehrte Damen und Herren, anbei erhalten Sie die Rechnung für den Monat Oktober. ",
        count: 400)
    private static let digits = String(repeating: "4711 0815 2026 1234 ", count: 400)

    /// Because the Mac counts about 2.3 prose characters or 1 digit per token.
    private static func tokens(_ text: String) -> Int {
        let digitCount = text.filter(\.isNumber).count
        let otherCount = text.count - digitCount
        return digitCount + Int((Double(otherCount) / 2.3).rounded(.up))
    }

    private static func cut(_ text: String, toTokens budget: Int) async -> String {
        try! await ModelInputCut.cut(text, toTokens: budget, countingWith: tokens)
    }

    private static func fitsAsPrefix(_ kept: String, of text: String) -> Bool {
        text.hasPrefix(kept) && tokens(kept) <= budget && tokens(kept) >= budget / 2
    }

    static func textWithinBudgetComesBackUnchanged() async {
        let text = String(prose.prefix(budget * 2))
        expect(await cut(text, toTokens: budget) == text, "text within the token budget comes back unchanged")
    }

    static func longProseIsCutToAPrefixWithinBudget() async {
        let kept = await cut(prose, toTokens: budget)
        expect(fitsAsPrefix(kept, of: prose), "long prose is cut to a prefix that fills at least half the budget without passing it")
    }

    static func digitHeavyTextIsCutToAPrefixWithinBudget() async {
        let text = digits + prose
        let kept = await cut(text, toTokens: budget)
        expect(fitsAsPrefix(kept, of: text),
               "text that starts with costly digits is cut to a prefix that fills at least half the budget without passing it")
    }

    static func emptyOrNegativeBudgetGivesEmptyText() async {
        let zero = await cut(prose, toTokens: 0)
        let negative = await cut(prose, toTokens: -5)
        expect([zero, negative] == ["", ""], "a zero or negative token budget keeps no text")
    }
}
