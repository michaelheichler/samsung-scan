import FoundationModels

enum LanguageModelAvailabilityChecks {
    static func run() {
        systemStatesMapToTheirReasons()
        onlyTheAvailableStateAllowsSuggestions()
        everyStateExplainsItselfDifferently()
    }

    private static let allStates: [LanguageModelAvailability] = [.available, .notEnabled, .notEligible, .notReady]

    static func systemStatesMapToTheirReasons() {
        let system: [SystemLanguageModel.Availability] = [
            .available,
            .unavailable(.appleIntelligenceNotEnabled),
            .unavailable(.deviceNotEligible),
            .unavailable(.modelNotReady),
        ]
        let mapped = system.map { LanguageModelAvailability($0) }
        expect(mapped == [.available, .notEnabled, .notEligible, .notReady],
               "each system availability maps to the matching reason")
    }

    static func onlyTheAvailableStateAllowsSuggestions() {
        expect(allStates.filter(\.isAvailable) == [.available], "only the available state allows suggestions")
    }

    static func everyStateExplainsItselfDifferently() {
        let messages = allStates.map(\.message)
        expect(Set(messages).count == allStates.count && !messages.contains(""),
               "every availability state shows its own non-empty message")
    }
}
