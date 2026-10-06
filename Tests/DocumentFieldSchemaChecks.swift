import Foundation

enum DocumentFieldSchemaChecks {
    static func run() async {
        eachFieldBecomesAnOptionalDescribedString()
        fieldWithChoicesBecomesARequiredStringEnum()
        await everyPagePairChoiceIsAnAnswerTheQuestionReads()
    }

    private struct EncodedSchema: Decodable {
        let properties: [String: Property]
        let required: [String]?
    }

    private struct Property: Decodable, Equatable {
        let description: String?
        let type: String
        let `enum`: [String]?
    }

    private static func encoded(_ fields: [DocumentField]) -> EncodedSchema {
        let schema = try! FoundationModelsClient.schema(for: fields)
        return try! JSONDecoder().decode(EncodedSchema.self, from: JSONEncoder().encode(schema))
    }

    static func eachFieldBecomesAnOptionalDescribedString() {
        let encoded = encoded([
            DocumentField(name: "sender", guide: "The company or person who wrote the letter"),
            DocumentField(name: "invoiceNumber", guide: "The number the sender gave this invoice"),
        ])
        let expected = [
            "sender": Property(description: "The company or person who wrote the letter", type: "string", enum: nil),
            "invoiceNumber": Property(
                description: "The number the sender gave this invoice", type: "string", enum: nil),
        ]
        expect(encoded.properties == expected && (encoded.required ?? []).isEmpty,
               "each document field becomes an optional string property described by its guide")
    }

    static func fieldWithChoicesBecomesARequiredStringEnum() {
        let encoded = encoded([
            DocumentField(name: "sender", guide: "The company or person who wrote the letter"),
            DocumentField(name: "paid", guide: "Whether the invoice is paid", choices: ["paid", "open"]),
        ])
        let expected = Property(description: "Whether the invoice is paid", type: "string", enum: ["paid", "open"])
        expect(
            encoded.properties["paid"] == expected && encoded.required == ["paid"],
            "a field with choices becomes a required string property limited to exactly those choices")
    }

    static func everyPagePairChoiceIsAnAnswerTheQuestionReads() async {
        let choices = encoded([PagePairQuestion.field]).properties[PagePairQuestion.field.name]?.enum ?? []
        let question = PagePairQuestion(endOfA: "Mit freundlichen Grüßen", startOfB: "Rechnung Nr. 4471")
        var readings: [Bool?] = []
        for choice in choices {
            readings.append(await question.startsNewDocument(using: FixedAnswerModel(answer: choice)))
        }
        expect(
            readings.count == 2 && Set(readings) == [true, false],
            "the page pair schema offers two choices, one read as a new document and one as the same document")
    }
}
