public struct ExportDocument: Equatable, Sendable {
    public let pages: [ScannedPage]
    public let name: ExportFileName

    public init(pages: [ScannedPage], name: ExportFileName) {
        self.pages = pages
        self.name = name
    }
}
