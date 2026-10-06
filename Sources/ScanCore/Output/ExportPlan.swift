public struct ExportPlan: Equatable, Sendable {
    public let documents: [ExportDocument]

    public init(documents: [ExportDocument]) {
        self.documents = documents.filter { !$0.pages.isEmpty }
    }

    public init(pages: [ScannedPage], ranges: [Range<Int>], name: (Range<Int>) -> ExportFileName) {
        self.init(documents: ranges.map { ExportDocument(pages: Array(pages[$0]), name: name($0)) })
    }

    // So that an export splits only where the user confirmed a split.
    public init(pages: [ScannedPage], splits: DocumentSplits, name: (Range<Int>) -> ExportFileName) {
        self.init(pages: pages, ranges: splits.documents(of: pages.map(\.id), includingSuggested: false), name: name)
    }

    public var pages: [ScannedPage] {
        documents.flatMap(\.pages)
    }

    // So that a page corrected or deleted after the sheet opened exports as it is.
    public func current(in stack: [ScannedPage]) -> ExportPlan {
        let byID = Dictionary(stack.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ExportPlan(documents: documents.map {
            ExportDocument(pages: $0.pages.compactMap { byID[$0.id] }, name: $0.name)
        })
    }

    // So that pages picked across documents still land in the file of their document.
    public func keeping(_ ids: Set<ScannedPage.ID>) -> ExportPlan {
        ExportPlan(documents: documents.map {
            ExportDocument(pages: $0.pages.filter { ids.contains($0.id) }, name: $0.name)
        })
    }

    public func joined() -> ExportPlan {
        guard let first = documents.first else { return self }
        return ExportPlan(documents: [ExportDocument(pages: pages, name: first.name)])
    }

    public func writesSeveralFiles(as format: ExportFormat) -> Bool {
        documents.count > 1 || (format.writesOneFilePerPage && pages.count > 1)
    }
}
