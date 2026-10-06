import SwiftUI

struct PageTileContent: View {
    let page: ScannedPage
    let number: Int
    let format: PageFormat?
    let cache: ThumbnailCache
    let isSelected: Bool
    let isDropTarget: Bool
    let isBlank: Bool

    var body: some View {
        VStack(spacing: PageTile.spacing) {
            Color.clear
                .aspectRatio(PageTile.slotAspectRatio, contentMode: .fit)
                .overlay {
                    PageThumbnail(page: page, cache: cache)
                        .aspectRatio(format?.aspectRatio ?? PageTile.slotAspectRatio, contentMode: .fit)
                        .shadow(radius: PageTile.shadowRadius)
                        .overlay(alignment: .top) {
                            if isBlank {
                                BlankPageBadge()
                            }
                        }
                }
            VStack {
                Text("Page \(number)")
                    .font(.callout)
                Text(format?.name ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(PageTile.padding)
        .background {
            RoundedRectangle(cornerRadius: PageTile.cornerRadius)
                .fill(.selection)
                .opacity(isSelected ? 1 : 0)
        }
        .overlay {
            RoundedRectangle(cornerRadius: PageTile.cornerRadius)
                .strokeBorder(.tint, lineWidth: PageTile.outlineWidth)
                .opacity(isDropTarget ? 1 : 0)
        }
    }
}
