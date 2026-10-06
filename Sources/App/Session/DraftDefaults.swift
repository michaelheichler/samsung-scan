enum DraftDefaults {
    static let preferredResolution = 300
    static let preferredPaperID = "iso-a4"
    // Because scanimage reports the device default source for an empty name.
    static let deviceDefaultSource = ""
    static let singlePageSourceKeyword = "flatbed"

    static func request(
        device: String,
        source: String,
        capabilities: ScannerCapabilities,
        papers: [PaperSize]
    ) -> ScanRequest {
        let paper = papers.first { $0.id == preferredPaperID } ?? papers.first
        let region = paper.map(ScanRegion.init(paper:)) ?? ScanRegion(widthMillimeters: 0, heightMillimeters: 0)
        return ScanRequest(
            deviceName: device,
            source: source,
            mode: capabilities.defaultMode ?? capabilities.modes.first ?? "",
            resolution: preferredResolution,
            region: region,
            pageLimit: pageLimit(for: source)
        ).validated(against: capabilities)
    }

    // So that a flatbed in batch mode stops after one page instead of looping.
    static func pageLimit(for source: String) -> Int? {
        source.localizedStandardContains(singlePageSourceKeyword) ? 1 : nil
    }
}
