import Foundation

// So that a runner whose Vision reads no text skips Vision checks with a cause.
enum VisionProbe {
    private static let word = "Rechnung"
    private static let failure = Task { await failureReason() }

    static func canReadText(for group: String) async -> Bool {
        guard let reason = await failure.value else { return true }
        print("skip  \(group): Vision cannot read text (\(reason))")
        return false
    }

    private static func failureReason() async -> String? {
        let page = PagePairSamples.render([word], atBottom: false, named: "vision probe", in: TemporaryFolder.make())
        let text: PageText
        do {
            text = try await TextRecognizer.recognize(fileAt: page)
        } catch {
            return "TextRecognizer threw \(String(describing: error))"
        }
        guard !text.transcript.contains(word) else { return nil }
        let read = text.transcript.isEmpty ? "Vision returned no text" : "Vision read \"\(text.transcript)\""
        return "\(read), \(text.lines.count) observations"
    }
}
