extension ScanSession {
    var scanArea: ScanArea? {
        currentCapabilities?.scanArea
    }

    var usesFlatbed: Bool {
        draft.map { DraftDefaults.pageLimit(for: $0.source) == 1 } ?? false
    }

    var canPreview: Bool {
        canScan && usesFlatbed && !showsPageGrid
    }

    var previewHelp: String {
        if draft != nil && !usesFlatbed {
            return "Preview needs the flatbed. On the document feeder it would pull a page through."
        }
        if showsPageGrid {
            return "Preview shows on the glass, which the page list hides. Export or discard the pages first."
        }
        return "Scan the whole glass at low resolution"
    }

    // So that Escape falls back to the preset the user picked last.
    func clearCustomRegion() {
        guard selectedRegion != nil else { return }
        let papers = availablePapers
        let preferred = [lastPickedPaperID, DraftDefaults.preferredPaperID].compactMap { id in
            papers.first { $0.id == id }
        }
        guard let paper = preferred.first ?? papers.first else { return }
        selectPaper(paper)
    }
}
