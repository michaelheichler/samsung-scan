import FoundationModels
import Observation

public enum LanguageModelAvailability: Equatable, Sendable {
    case available
    case notEnabled
    case notEligible
    case notReady

    public static var current: LanguageModelAvailability {
        LanguageModelAvailability(SystemLanguageModel.default.availability)
    }

    // Because SystemLanguageModel is Observable, its availability reports each change.
    public static var updates: Observations<LanguageModelAvailability, Never> {
        Observations { LanguageModelAvailability.current }
    }

    public init(_ availability: SystemLanguageModel.Availability) {
        switch availability {
        case .available:
            self = .available
        case .unavailable(.appleIntelligenceNotEnabled):
            self = .notEnabled
        case .unavailable(.deviceNotEligible):
            self = .notEligible
        case .unavailable(.modelNotReady):
            self = .notReady
        case .unavailable:
            self = .notReady
        }
    }

    public var isAvailable: Bool { self == .available }

    public var message: String {
        switch self {
        case .available:
            "Apple Intelligence is ready for document suggestions."
        case .notEnabled:
            "Turn on Apple Intelligence in System Settings to get document suggestions."
        case .notEligible:
            "This Mac does not support Apple Intelligence, so document suggestions are off."
        case .notReady:
            "Apple Intelligence is not ready yet. Document suggestions start once it is ready."
        }
    }
}
