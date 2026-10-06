import SwiftUI

struct OutsideDim: Shape {
    let glass: CGRect
    var selection: CGRect

    var animatableData: CGRect.AnimatableData {
        get { selection.animatableData }
        set { selection.animatableData = newValue }
    }

    // Because the even-odd fill rule leaves the selection undimmed.
    func path(in rect: CGRect) -> Path {
        var path = Path(glass)
        path.addRect(selection)
        return path
    }
}
