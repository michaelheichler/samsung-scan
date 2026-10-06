enum ExportScope: String, CaseIterable, Identifiable {
    case all
    case selected

    var id: Self { self }
}
