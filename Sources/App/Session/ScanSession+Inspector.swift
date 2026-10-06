extension ScanSession {
    var selectedPaperID: String? {
        get { draft?.region.matchingPaper(in: availablePapers)?.id }
        set {
            guard let paper = availablePapers.first(where: { $0.id == newValue }) else { return }
            selectPaper(paper)
        }
    }

    // So that the source and mode lists stay put while a new source loads.
    var inspectorCapabilities: ScannerCapabilities? {
        currentCapabilities ?? capabilitiesBySource.values.first
    }
}
