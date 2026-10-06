public enum ModelInputCut {
    /// Because characters per token range from 1 for numbers to 2.5 for prose.
    public static func cut(
        _ text: String,
        toTokens budget: Int,
        countingWith count: (String) async throws -> Int
    ) async throws -> String {
        var kept = text
        var tokens = try await count(kept)
        while tokens > budget, !kept.isEmpty {
            let estimate = kept.count * max(budget, 0) * 9 / (tokens * 10)
            kept = String(kept.prefix(min(estimate, kept.count - 1)))
            tokens = try await count(kept)
        }
        return kept
    }
}
