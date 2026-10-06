import AppKit
import SwiftUI

struct PageTile: View {
    // So that portrait A4 fills the slot and other formats stay in proportion.
    static let slotAspectRatio = 210.0 / 297.0
    static let spacing = 8.0
    static let padding = 8.0
    static let cornerRadius = 8.0
    static let shadowRadius = 2.0
    static let outlineWidth = 2.0

    let page: ScannedPage
    let number: Int
    let session: ScanSession
    let cache: ThumbnailCache
    let open: (ScannedPage) -> Void
    @ViewState private var format: PageFormat?
    @ViewState private var isDropTarget = false

    private var isSelected: Bool {
        session.pageSelection.ids.contains(page.id)
    }

    private var isBlank: Bool {
        session.isBlank(page)
    }

    private var accessibilityText: String {
        let size = format.map { ", \($0.name)" } ?? ""
        let blank = isBlank ? ", blank page" : ""
        return "Page \(number) of \(session.pages.count)\(size)\(blank)"
    }

    private var accessibilityTraits: AccessibilityTraits {
        isSelected ? [.isButton, .isSelected] : .isButton
    }

    var body: some View {
        PageTileContent(
            page: page, number: number, format: format, cache: cache,
            isSelected: isSelected, isDropTarget: isDropTarget, isBlank: isBlank)
        .contentShape(.rect(cornerRadius: Self.cornerRadius))
        .onTapGesture(count: 2, perform: openPage)
        .simultaneousGesture(TapGesture().onEnded(click))
        .contextMenu {
            PageTileMenu(page: page, number: number, session: session, open: open)
        }
        .draggable(PageDrag(page: page, number: number, workFolder: session.workFolder))
        .dropDestination(for: String.self, action: drop)
        .onDropSessionUpdated(trackDrop)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityAction(.default, click)
        .accessibilityAction(named: "Open", openPage)
        .task(loadFormat)
    }

    private func click() {
        let modifiers = NSEvent.modifierFlags
        if modifiers.contains(.command) {
            session.pageSelection.toggle(page.id)
        } else if modifiers.contains(.shift) {
            session.pageSelection.extend(to: page.id, in: session.pageIDs)
        } else {
            session.pageSelection.select(page.id)
        }
    }

    private func openPage() {
        open(page)
    }

    private func drop(_ ids: [String], _ drop: DropSession) {
        isDropTarget = false
        guard let id = ids.first.flatMap(UUID.init(uuidString:)) else { return }
        session.movePage(withID: id, onto: page)
    }

    private func trackDrop(_ drop: DropSession) {
        isDropTarget = drop.phase == .entering || drop.phase == .active
    }

    private func loadFormat() async {
        format = await cache.format(of: page, catalog: session.paperCatalog)
    }
}
