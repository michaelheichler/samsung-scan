import SwiftUI

struct PendingPageTile: View {
    private static let dash: [CGFloat] = [6, 4]

    let number: Int
    let format: PageFormat?

    var body: some View {
        VStack(spacing: PageTile.spacing) {
            Color.clear
                .aspectRatio(PageTile.slotAspectRatio, contentMode: .fit)
                .overlay {
                    RoundedRectangle(cornerRadius: PageTile.cornerRadius)
                        .strokeBorder(.secondary, style: StrokeStyle(lineWidth: PageTile.outlineWidth, dash: Self.dash))
                        .overlay {
                            ProgressView()
                        }
                        .aspectRatio(format?.aspectRatio ?? PageTile.slotAspectRatio, contentMode: .fit)
                }
            VStack {
                Text("Page \(number)")
                    .font(.callout)
                Text("Scanning…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(PageTile.padding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(number), scanning")
    }
}
