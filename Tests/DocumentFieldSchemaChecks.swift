import Foundation

enum DocumentFieldSchemaChecks {
    static func run() {
        eachFieldBecomesAnOptionalDescribedString()
    }

    private struct EncodedSchema: Decodable {
        let properties: [String: Property]
        let required: [String]?
    }

    private struct Property: Decodable, Equatable {
        let description: String?
        let type: String
    }

    static func eachFieldBecomesAnOptionalDescribedString() {
        let fields = [
            DocumentField(name: "sender", guide: "The company or person who wrote the letter"),
            DocumentField(name: "invoiceNumber", guide: "The number the sender gave this invoice"),
        ]
        let schema = try! FoundationModelsClient.schema(for: fields)
        let encoded = try! JSONDecoder().decode(EncodedSchema.self, from: JSONEncoder().encode(schema))
        let expected = [
            "sender": Property(description: "The company or person who wrote the letter", type: "string"),
            "invoiceNumber": Property(description: "The number the sender gave this invoice", type: "string"),
        ]
        expect(encoded.properties == expected && (encoded.required ?? []).isEmpty,
               "each document field becomes an optional string property described by its guide")
    }
}
