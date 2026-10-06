import Foundation

public struct PageText: Equatable, Sendable {
    public let transcript: String
    public let lines: [RecognizedLine]
    // So that date and amount work without the language model, Vision finds them.
    public let dates: [Date]
    public let amounts: [DocumentAmount]

    public init(transcript: String, lines: [RecognizedLine], dates: [Date] = [], amounts: [DocumentAmount] = []) {
        self.transcript = transcript
        self.lines = lines
        self.dates = dates
        self.amounts = amounts
    }
}
