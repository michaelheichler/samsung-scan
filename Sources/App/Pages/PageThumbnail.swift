import SwiftUI

struct PageThumbnail: View {
    // So that small resizes reuse the decoded image instead of decoding again.
    private static let pixelStep = 64.0

    let page: ScannedPage
    let cache: ThumbnailCache
    @Environment(\.displayScale) private var displayScale
    @ViewState private var image: CGImage?
    @ViewState private var maxPixelSize = 0

    var body: some View {
        Rectangle()
            .fill(.white)
            .overlay(alignment: .top) {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .onGeometryChange(for: CGSize.self, of: \.size, action: resize)
            .task(id: maxPixelSize, load)
    }

    private func resize(to size: CGSize) {
        let longestSide = max(size.width, size.height) * displayScale
        maxPixelSize = Int((longestSide / Self.pixelStep).rounded(.up) * Self.pixelStep)
    }

    private func load() async {
        guard maxPixelSize > 0 else { return }
        let decoded = await cache.image(of: page, maxPixelSize: maxPixelSize)
        if !Task.isCancelled {
            image = decoded
        }
    }
}
