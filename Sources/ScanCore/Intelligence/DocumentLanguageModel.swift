/// So that checks and previews can stand in for the on-device model.
public protocol DocumentLanguageModel: Sendable {
    func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String]
}
