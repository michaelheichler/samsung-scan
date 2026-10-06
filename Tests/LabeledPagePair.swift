// So that a sample pair carries the answer a person gave for it.
struct LabeledPagePair {
    let name: String
    let endOfA: [String]
    let startOfB: [String]
    let startsNewDocument: Bool
}
