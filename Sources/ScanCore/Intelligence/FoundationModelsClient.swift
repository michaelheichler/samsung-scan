import Foundation
import FoundationModels

public struct FoundationModelsClient: DocumentLanguageModel {
    /// So that instructions, the field schema, and the answer fit beside the text.
    static let reservedTokens = 1536

    // Because "one document" here made the model join most page pairs.
    static let instructions = """
        The prompt holds text from scanned paper. Fill each field from that text only. \
        Leave a field out when the text does not state it.
        """

    private let model: SystemLanguageModel

    public init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    public func fields(_ fields: [DocumentField], from text: String) async throws -> [String: String] {
        let prompt = try await ModelInputCut.cut(
            text, toTokens: model.contextSize - Self.reservedTokens, countingWith: tokenCount)
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        // So that the same pages give the same facts and splits on every run.
        let response = try await session.respond(
            to: prompt, schema: try Self.schema(for: fields), options: GenerationOptions(samplingMode: .greedy))
        var values: [String: String] = [:]
        for field in fields {
            let value = try response.content.value(String?.self, forProperty: field.name)
            if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                values[field.name] = value
            }
        }
        return values
    }

    static func schema(for fields: [DocumentField]) throws -> GenerationSchema {
        let properties = fields.map { field in
            guard !field.choices.isEmpty else {
                return DynamicGenerationSchema.Property(
                    name: field.name, description: field.guide,
                    schema: DynamicGenerationSchema(type: String.self), isOptional: true)
            }
            // Because a decision has no "not stated" case, the model must pick one choice.
            return DynamicGenerationSchema.Property(
                name: field.name, description: field.guide,
                schema: DynamicGenerationSchema(name: field.name, anyOf: field.choices))
        }
        let root = DynamicGenerationSchema(name: "DocumentFields", properties: properties)
        return try GenerationSchema(root: root, dependencies: [])
    }

    private func tokenCount(_ text: String) async throws -> Int {
        if #available(macOS 26.4, *) {
            return try await model.tokenCount(for: text)
        }
        // Because a byte-level tokenizer never needs more tokens than bytes.
        return text.utf8.count
    }
}
