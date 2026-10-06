import SwiftUI

struct PageGrid: View {
    static let tileMinimumWidth = 180.0
    private static let spacing = 16.0
    private static let pendingTileID = UUID()

    let session: ScanSession
    @ViewState private var cache = ThumbnailCache()
    @ViewState private var detailPage: ScannedPage?
    @ViewState private var scrollPosition = ScrollPosition(idType: UUID.self)
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Self.tileMinimumWidth), spacing: Self.spacing, alignment: .top)],
                spacing: Self.spacing
            ) {
                ForEach(session.pages.enumerated(), id: \.element.id) { index, page in
                    PageTile(page: page, number: index + 1, session: session, cache: cache, open: open)
                }
                if let number = session.pendingPageNumber {
                    PendingPageTile(number: number, format: session.pendingPageFormat)
                        .id(Self.pendingTileID)
                }
            }
            .scrollTargetLayout()
            .padding(Self.spacing)
        }
        .scrollPosition($scrollPosition)
        .onChange(of: session.pendingPageNumber, initial: true, revealPendingTile)
        .background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: clearSelection)
                .accessibilityHidden(true)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .simultaneousGesture(TapGesture().onEnded(focus))
        .onKeyPress(.space, action: openSelection)
        .onDeleteCommand(perform: session.deleteSelectedPages)
        .onMoveCommand(perform: moveSelection)
        .sheet(item: $detailPage) { page in
            PageDetail(page: page, session: session, cache: cache)
        }
    }

    private func open(_ page: ScannedPage) {
        session.pageSelection.select(page.id)
        detailPage = page
    }

    private func openSelection() -> KeyPress.Result {
        guard let page = session.selectedPages.first else { return .ignored }
        open(page)
        return .handled
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        switch direction {
        case .left: session.pageSelection.step(by: -1, in: session.pageIDs)
        case .right: session.pageSelection.step(by: 1, in: session.pageIDs)
        default: break
        }
    }

    private func revealPendingTile() {
        guard session.pendingPageNumber != nil else { return }
        withAnimation {
            scrollPosition.scrollTo(id: Self.pendingTileID, anchor: .bottom)
        }
    }

    private func clearSelection() {
        session.pageSelection.clear()
    }

    private func focus() {
        isFocused = true
    }
}
