import SwiftUI

struct GlassSurface: View {
    private static let cornerRadius = 3.0

    let mapping: CanvasMapping
    let picture: PreviewPicture?

    var body: some View {
        let glass = mapping.glass
        let extent = picture?.extent.map { mapping.rect(for: $0).size } ?? glass.size
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(.quaternary)
            if let picture {
                Image(picture.image, scale: 1, label: Text("Preview scan"))
                    .resizable()
                    .interpolation(.medium)
                    .frame(width: extent.width, height: extent.height)
            }
        }
        .frame(width: glass.width, height: glass.height, alignment: .topLeading)
        .clipShape(.rect(cornerRadius: Self.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(.separator)
        }
        .position(x: glass.midX, y: glass.midY)
    }
}
