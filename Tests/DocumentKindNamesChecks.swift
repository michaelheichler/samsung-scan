import Foundation

enum DocumentKindNamesChecks {
    static func run() {
        bundledTableNamesEveryKind(in: "en")
        bundledTableNamesEveryKind(in: "de")
    }

    private static func bundledWords(in language: String) -> [String: String] {
        let table = try? DocumentKindNames(contentsOf: PaperCatalog.locateResource(
            named: DocumentKindNames.resourceFileName, bundleResources: nil))
        return table?.words[language] ?? [:]
    }

    static func bundledTableNamesEveryKind(in language: String) {
        let words = bundledWords(in: language)
        let named = DocumentKind.allCases.allSatisfy { words[$0.rawValue]?.isEmpty == false }
        expect(named, "the bundled kind words in \(language) name every document kind")
    }
}
