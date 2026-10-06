public struct ExportPlan: Equatable, Sendable {
    public let documents: [ExportDocument]

    public init(documents: [ExportDocument]) {
        self.documents = documents.filter { !$0.pages.isEmpty }
    }

    public init(pages: [ScannedPage], ranges: [Range<Int>], name: (Range<Int>) -> ExportFileName) {
        self.init(documents: ranges.map { ExportDocument(pages: Array(pages[$0]), name: name($0)) })
    }

    public var pages: [ScannedPage] {
        documents.flatMap(\.pages)
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
