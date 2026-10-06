public struct PageText: Equatable, Sendable {
    public let transcript: String
    public let lines: [RecognizedLine]

    public init(transcript: String, lines: [RecognizedLine]) {
        self.transcript = transcript
        self.lines = lines
    }
}
