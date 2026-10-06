import SwiftUI

struct RegionSizeLabel: View {
    private static let gap = 8.0
    private static let halfWidth = 64.0
    private static let halfHeight = 14.0
    private static let padding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

    let text: String
    let selection: CGRect
    let bounds: CGSize

    // So that the label sits below the selection but never leaves the canvas.
    private var center: CGPoint {
        CGPoint(
            x: min(max(selection.midX, Self.halfWidth), bounds.width - Self.halfWidth),
            y: min(selection.maxY + Self.gap + Self.halfHeight, bounds.height - Self.halfHeight)
        )
    }

    var body: some View {
        Text(text)
            .font(.callout.monospacedDigit())
            .fixedSize()
            .padding(Self.padding)
            .background(.regularMaterial, in: .capsule)
            .position(center)
            .allowsHitTesting(false)
    }
}
