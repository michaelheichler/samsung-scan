import Foundation

extension ScanSession {
    var pageIDs: [ScannedPage.ID] {
        pages.map(\.id)
    }

    var selectedPageIDs: Set<ScannedPage.ID> {
        pageSelection.ids.intersection(pageIDs)
    }

    var selectedPages: [ScannedPage] {
        pages.filter { pageSelection.ids.contains($0.id) }
    }

    var canEditPages: Bool {
        !pages.isEmpty && !phase.isBusy
    }

    var pendingPageNumber: Int? {
        guard case .scanning = phase else { return nil }
        return pages.count + 1
    }

    var pendingPageFormat: PageFormat? {
        draft.map { PageFormat(region: $0.region, catalog: paperCatalog) }
    }

    var showsPageGrid: Bool {
        !pages.isEmpty || pendingPageNumber != nil
    }

    func deleteSelectedPages() {
        guard canEditPages else { return }
        for page in selectedPages {
            remove(page)
        }
        pageSelection.clear()
    }

    // So that Delete on a page inside the selection removes the whole selection.
    func delete(_ page: ScannedPage) {
        if pageSelection.ids.contains(page.id) {
            deleteSelectedPages()
        } else if canEditPages {
            remove(page)
        }
    }

    func movePage(withID id: ScannedPage.ID, onto target: ScannedPage) {
        guard canEditPages,
              let page = pages.first(where: { $0.id == id }),
              let start = pages.firstIndex(of: page),
              let end = pages.firstIndex(of: target) else { return }
        let step = end > start ? 1 : -1
        for _ in stride(from: start, to: end, by: step) {
            move(page, by: step)
        }
    }
}
