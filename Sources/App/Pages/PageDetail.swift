import SwiftUI

struct PageDetail: View {
    private static let minimumWidth = 560.0
    private static let minimumHeight = 640.0
    private static let idealWidth = 760.0
    private static let idealHeight = 960.0
    private static let shadowRadius = 4.0

    let session: ScanSession
    let cache: ThumbnailCache
    @ViewState private var pageID: ScannedPage.ID
    @ViewState private var format: PageFormat?
    @Environment(\.dismiss) private var dismiss

    init(page: ScannedPage, session: ScanSession, cache: ThumbnailCache) {
        self.session = session
        self.cache = cache
        _pageID = ViewState(initialValue: page.id)
    }

    private var index: Int? {
        session.pages.firstIndex { $0.id == pageID }
    }

    var body: some View {
        VStack {
            if let index {
                PageThumbnail(page: session.pages[index], cache: cache)
                    .aspectRatio(format?.aspectRatio ?? PageTile.slotAspectRatio, contentMode: .fit)
                    .shadow(radius: Self.shadowRadius)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(pageID)
                    .accessibilityLabel(title(at: index))
            } else {
                ContentUnavailableView("Page Removed", systemImage: "doc.questionmark")
            }
            DocumentFactsLine(facts: session.documentFacts)
            PageDetailBar(
                title: index.map(title(at:)) ?? "",
                hasPrevious: (index ?? 0) > 0,
                hasNext: (index ?? session.pages.count) < session.pages.count - 1,
                previous: showPrevious,
                next: showNext,
                close: close)
        }
        .padding()
        .frame(
            minWidth: Self.minimumWidth, idealWidth: Self.idealWidth,
            minHeight: Self.minimumHeight, idealHeight: Self.idealHeight)
        .focusable(true)
        .focusEffectDisabled()
        .onKeyPress(.space, action: closeFromKey)
        .task(id: pageID, loadFormat)
    }

    private func title(at index: Int) -> String {
        let name = format.map { ", \($0.name)" } ?? ""
        return "Page \(index + 1) of \(session.pages.count)\(name)"
    }

    private func showPrevious() {
        step(by: -1)
    }

    private func showNext() {
        step(by: 1)
    }

    private func step(by offset: Int) {
        guard let index, session.pages.indices.contains(index + offset) else { return }
        pageID = session.pages[index + offset].id
        session.pageSelection.select(pageID)
    }

    private func close() {
        dismiss()
    }

    private func closeFromKey() -> KeyPress.Result {
        dismiss()
        return .handled
    }

    private func loadFormat() async {
        guard let index else { return }
        format = await cache.format(of: session.pages[index], catalog: session.paperCatalog)
    }
}
