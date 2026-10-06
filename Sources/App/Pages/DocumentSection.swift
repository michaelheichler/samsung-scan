struct DocumentSection: Identifiable {
    let number: Int
    let pages: Range<Int>
    let firstPage: ScannedPage
    let name: ExportFileName
    let split: DocumentSplitState

    var id: ScannedPage.ID {
        firstPage.id
    }
}
