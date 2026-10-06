import SwiftUI

struct PlacedRectangle: Shape {
    var rect: CGRect

    var animatableData: CGRect.AnimatableData {
        get { rect.animatableData }
        set { rect.animatableData = newValue }
    }

    func path(in _: CGRect) -> Path {
        Path(rect)
    }
}
