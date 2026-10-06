enum ExportGrouping: String, CaseIterable, Identifiable {
    case filePerDocument
    case oneFile

    var id: Self { self }
}
